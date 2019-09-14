"""
    benchmarkpkg(pkg, [target]::Union{String, BenchmarkConfig}; kwargs...)

Run a benchmark on the package `pkg` using the [`BenchmarkConfig`](@ref) or git identifier `target`.
Examples of git identifiers are commit shas, branch names, or e.g. `"HEAD~1"`.
Return a [`BenchmarkResults`](@ref).

The argument `pkg` can be a name of a package or a path to a directory to a package.

**Keyword arguments**:

* `script` - The script with the benchmarks, if not given, defaults to `benchmark/benchmarks.jl` in the package folder.
* `postprocess` - A function to post-process results. Will be passed the `BenchmarkGroup`, which it can modify, or return a new one.
* `resultfile` - If set, saves the output to `resultfile`
* `retune` - Force a re-tune, saving the new tuning to the tune file.

The result can be used by functions such as [`judge`](@ref). If you choose to, you can save the results manually using
[`writeresults`](@ref) where `results` is the return value of this function. It can be read back with [`readresults`](@ref).

**Example invocations:**

```julia
using PkgBenchmark

import MyPkg
benchmarkpkg(pathof(MyPkg)) # run the benchmarks at the current state of the repository
benchmarkpkg(pathof(MyPkg), "my-feature") # run the benchmarks for a particular branch/commit/tag
benchmarkpkg(pathof(MyPkg), "my-feature"; script="/home/me/mycustombenchmark.jl")
benchmarkpkg(pathof(MyPkg), BenchmarkConfig(id = "my-feature",
                                            env = Dict("JULIA_NUM_THREADS" => 4),
                                            juliacmd = `julia -O3`))
benchmarkpkg(pathof(MyPkg),  # Run the benchmarks and divide the (median of) results by 1000
    postprocess=(results)->(results["g"] = median(results["g"])/1_000)
```
"""
function benchmarkpkg(
        pkg::String,
        target=BenchmarkConfig();
        script=nothing,
        postprocess=nothing,
        resultfile=nothing,
        retune=false,
        custom_loadpath="" #= used in tests =#
    )
    target = BenchmarkConfig(target)

    pkgid = Base.identify_package(pkg)
    pkgfile_from_pkgname = pkgid === nothing ? nothing : Base.locate_package(pkgid)

    if pkgfile_from_pkgname===nothing
        if isdir(pkg)
            pkgdir = pkg
        else
            error("No package '$pkg' found.")
        end
    else
        pkgdir = normpath(joinpath(dirname(pkgfile_from_pkgname), ".."))
    end

    # Locate script
    if script === nothing
        script = joinpath(pkgdir, "benchmark", "benchmarks.jl")
    elseif !isabspath(script)
        script = joinpath(pkgdir, script)
    end

    if !isfile(script)
        error("benchmark script at $script not found")
    end

    # Locate pacakge
    tunefile = joinpath(pkgdir, "benchmark", "tune.json")

    isgitrepo = isdir(joinpath(pkgdir, ".git"))
    if isgitrepo
        isdirty = LibGit2.with(LibGit2.isdirty, LibGit2.GitRepo(pkgdir))
        original_sha = _shastring(pkgdir, "HEAD")
    end

    # In this function the package is at the commit we want to benchmark
    function do_benchmark()
        shastring = begin
            if isgitrepo
                isdirty ? "dirty" : _shastring(pkgdir, "HEAD")
            else
                "non gitrepo"
            end
        end

        local results
        results_local = _withtemp(tempname()) do f
            _benchinfo("Running benchmarks...")
            _runbenchmark(script, f, target, tunefile; retune=retune, custom_loadpath = custom_loadpath)
        end
        io = IOBuffer(results_local["results"])
        seek(io, 0)
        resgroup = BenchmarkTools.load(io)[1]
        if postprocess != nothing
            retval = postprocess(resgroup)
            if retval != nothing
                resgroup = retval
            end
        end
        juliasha = results_local["juliasha"]
        vinfo = results_local["vinfo"]
        results = BenchmarkResults(pkg, shastring, resgroup, now(), juliasha, vinfo, target)
        return results
    end

    if target.id !== nothing
        if !isgitrepo
            error("$pkgdir is not a git repo, cannot benchmark at $(target.id)")
        elseif isdirty
            error("$pkgdir is dirty. Please commit/stash your ",
                  "changes before benchmarking a specific commit")
        end
        results = _withcommit(do_benchmark, LibGit2.GitRepo(pkgdir), target.id)
    else
        results = do_benchmark()
    end

    if resultfile != nothing
        writeresults(resultfile, results)
        _benchinfo("benchmark results written to $resultfile")
    end
    if isgitrepo
        after_sha = _shastring(pkgdir, "HEAD")
        if original_sha != after_sha
            @warn("Failed to return back to original sha $original_sha, package now at $after_sha")
        end
    end
    return results
end

function _runbenchmark(file::String, output::String, benchmarkconfig::BenchmarkConfig, tunefile::String;
                      retune=false, custom_loadpath = nothing)
    color = Base.have_color ? "--color=yes" : "--color=no"
    compilecache = "--compiled-modules=" * (Bool(Base.JLOptions().use_compiled_modules) ? "yes" : "no")
    _file, _output, _tunefile, _custom_loadpath = map(escape_string, (file, output, tunefile, custom_loadpath))
    codecov_option = Base.JLOptions().code_coverage
    coverage = if codecov_option == 0
        "none"
    elseif codecov_option == 1
        "user"
    else
        "all"
    end
    exec_str = isempty(_custom_loadpath) ? "" : "push!(LOAD_PATH, \"$(_custom_loadpath)\")\n"
    exec_str *=
        """
        using PkgBenchmark
        PkgBenchmark._runbenchmark_local("$_file", "$_output", "$_tunefile", $retune )
        """

    target_env = [k => v for (k, v) in benchmarkconfig.env]
    withenv(target_env...) do
        env_to_use = dirname(Pkg.Types.Context().env.project_file)
        run(`$(benchmarkconfig.juliacmd) --project=$env_to_use --depwarn=no --code-coverage=$coverage $color $compilecache -e $exec_str`)
    end
    return JSON.parsefile(output)
end


function _runbenchmark_local(file, output, tunefile, retune)
    # Loading
    Base.include(Main, file)
    if !isdefined(Main, :SUITE)
        error("`SUITE` variable not found, make sure the BenchmarkGroup is named `SUITE`")
    end
    suite = Main.SUITE

    # Tuning
    if isfile(tunefile) && !retune
        _benchinfo("using benchmark tuning data in $(abspath(tunefile))")
        BenchmarkTools.loadparams!(suite, BenchmarkTools.load(tunefile)[1], :evals, :samples);
    else
        _benchinfo("creating benchmark tuning file $(abspath(tunefile))...")
        mkpath(dirname(tunefile))
        _tune!(suite)
        BenchmarkTools.save(tunefile, params(suite));
    end

    # Running
    results = _run(suite)

    # Output
    vinfo = first(split(sprint((io) -> versioninfo(io; verbose=true)), "Environment"))
    juliasha = Base.GIT_VERSION_INFO.commit

    open(output, "w") do iof
        JSON.print(iof, Dict(
            "results"  => sprint(BenchmarkTools.save, results),
            "vinfo"    => vinfo,
            "juliasha" => juliasha,
        ))
    end
    return nothing
end


function _tune!(group::BenchmarkTools.BenchmarkGroup; verbose::Bool = false, root = true,
                prog = Progress(length(BenchmarkTools.leaves(group)); desc = "Tuning: "), hierarchy = [], kwargs...)
    BenchmarkTools.gcscrub() # run GC before running group, even if individual benchmarks don't manually GC
    i = 1
    for id in keys(group)
        _tune!(group[id]; verbose = verbose, prog = prog, hierarchy = push!(copy(hierarchy), (repr(id), i, length(keys(group)))), kwargs...)
        i += 1
    end
    return group
end

function _tune!(b::BenchmarkTools.Benchmark, p::BenchmarkTools.Parameters = b.params;
               prog = nothing, verbose::Bool = false, pad = "", hierarchy = [], kwargs...)
    BenchmarkTools.warmup(b, verbose=false)
    estimate = ceil(Int, minimum(BenchmarkTools.lineartrial(b, p; kwargs...)))
    b.params.evals = BenchmarkTools.guessevals(estimate)
    if prog != nothing
        indent = 0
        ProgressMeter.next!(prog; showvalues = [map(id -> ("  "^(indent += 1) * "[$(id[2])/$(id[3])]", id[1]), hierarchy)...])
    end
    return b
end

function _run(group::BenchmarkTools.BenchmarkGroup, args...;
              prog = Progress(length(BenchmarkTools.leaves(group)); desc = "Benchmarking: "), hierarchy = [], kwargs...)
    result = similar(group)
    BenchmarkTools.gcscrub() # run GC before running group, even if individual benchmarks don't manually GC
    i = 1
    for id in keys(group)
        result[id] = _run(group[id], args...; prog = prog, hierarchy = push!(copy(hierarchy), (repr(id), i, length(keys(group)))), kwargs...)
        i += 1
    end
    return result
end

function _run(b::BenchmarkTools.Benchmark, p::BenchmarkTools.Parameters = b.params;
                   prog = nothing, verbose::Bool = false, pad = "", hierarchy = [], kwargs...)
    res = BenchmarkTools.run_result(b, p; kwargs...)[1]
    if prog != nothing
        indent = 0
        ProgressMeter.next!(prog; showvalues = [map(id -> ("  "^(indent += 1) * "[$(id[2])/$(id[3])]", id[1]), hierarchy)...])
    end
    return res
end
