"""
    benchmarkpkg(pkg, [target]::Union{String, BenchmarkConfig}; kwargs...)

Run a benchmark on the package `pkg` using the [`BenchmarkConfig`](@ref) or git identifier `target`.
Examples of git identifiers are commit shas, branch names, or e.g. "HEAD~1".
Return a [`BenchmarkResults`](@ref).

The argument `pkg` can be a name of a package or a path to a directory to a package.

**Keyword arguments**:

* `script` - The script with the benchmarks, if not given, defaults to `benchmark/benchmarks.jl` in the package folder.
* `resultfile` - If set, saves the output to `resultfile`
* `retune` - Force a re-tune, saving the new tuning to the tune file.

The result can be used by functions such as [`judge`](@ref). If you choose to, you can save the results manually using
[`writeresults`](@ref) where `results` is the return value of this function. It can be read back with [`readresults`](@ref).

If a `REQUIRE` file exists in the same folder as `script`, load package requirements from that file before benchmarking.

**Example invocations:**

```julia
using PkgBenchmark

benchmarkpkg("MyPkg") # run the benchmarks at the current state of the repository
benchmarkpkg("MyPkg", "my-feature") # run the benchmarks for a particular branch/commit/tag
benchmarkpkg("MyPkg", "my-feature"; script="/home/me/mycustombenchmark.jl")
benchmarkpkg("MyPkg", BenchmarkConfig(id = "my-feature",
                                      env = Dict("JULIA_NUM_THREADS" => 4),
                                      juliacmd = `julia -O3`))
```
"""
function benchmarkpkg(
        pkg::String,
        target=BenchmarkConfig();
        script=nothing,
        resultfile=nothing,
        retune=false,
        custom_loadpath="" #= used in tests =#
    )
    target = BenchmarkConfig(target)

    # Locate script
    if script === nothing
        if isdir(Pkg.dir(pkg))
            script = Pkg.dir(pkg, "benchmark", "benchmarks.jl")
        end
    end
    if !isfile(script)
        error("bencmark script at $script not found")
    end

    # Locate pacakge
    if isdir(Pkg.dir(pkg))
        pkgdir = Pkg.dir(pkg)
        tunefile = Pkg.dir(".pkgbenchmark", "$(pkg)_tune.json")
    else
        pkgdir = pkg
        tunefile = joinpath(pkgdir, "tune.json")
        if !isdir(pkgdir)
            error("package directory at $pkgdir not found")
        end
    end

    isgitrepo = isdir(joinpath(pkgdir, ".git"))
    if isgitrepo
        isdirty = LibGit2.with(LibGit2.isdirty, LibGit2.GitRepo(pkgdir))
        original_sha = _shastring(Pkg.dir(pkg), "HEAD")
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
        results_local = _with_reqs(joinpath(dirname(script), "REQUIRE"), () -> info("Resolving dependencies for benchmark...")) do
            _withtemp(tempname()) do f
                _benchinfo("Running benchmarks...")
                _runbenchmark(script, f, target, tunefile; retune=retune, custom_loadpath = custom_loadpath)
            end
        end
        io = IOBuffer(results_local["results"])
        seek(io, 0)
        resgroup = BenchmarkTools.load(io)[1]
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
            warn("Failed to return back to original sha $original_sha, package now at $after_sha")
        end
    end
    return results
end

function _runbenchmark(file::String, output::String, benchmarkconfig::BenchmarkConfig, tunefile::String;
                      retune=false, custom_loadpath = nothing)
    color = Base.have_color ? "--color=yes" : "--color=no"
    compilecache = "--compilecache=" * (Bool(Base.JLOptions().use_compilecache) ? "yes" : "no")
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
        run(`$(benchmarkconfig.juliacmd) --depwarn=no --code-coverage=$coverage $color $compilecache -e $exec_str`)
    end
    return JSON.parsefile(output)
end

function _runbenchmark_local(file, output, tunefile, retune)
    # Loading
    include(file)
    suite = if isdefined(Main, :SUITE)
        Main.SUITE
    else
        error("`SUITE` variable not found, make sure the BenchmarkGroup is named `SUITE`")
    end

    # Tuning
    if isfile(tunefile) && !retune
        _benchinfo("using benchmark tuning data in $tunefile")
        BenchmarkTools.loadparams!(suite, BenchmarkTools.load(tunefile)[1], :evals, :samples);
    else
        _benchinfo("creating benchmark tuning file $tunefile...")
        mkpath(dirname(tunefile))
        _tune!(suite)
        BenchmarkTools.save(tunefile, params(suite));
    end

    # Running
    results = _run(suite)

    # Output
    vinfo = first(split(read(`julia -e 'versioninfo(true)'`, String), "Environment"))
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
