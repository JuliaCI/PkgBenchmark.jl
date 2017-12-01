# Package benchmarking API

defaultscript(pkg)     = Pkg.dir(pkg, "benchmark", "benchmarks.jl")
defaultrequire(pkg)    = Pkg.dir(pkg, "benchmark", "REQUIRE")
defaultresultsdir(pkg) = Pkg.dir(".benchmarks", pkg, "results")
defaulttunefile(pkg)   = Pkg.dir(".benchmarks", pkg, ".tune.jld")

"""
    benchmarkpkg(pkg, [target]::Union{String, BenchmarkConfig};
                saveresults = true,
                retune      = false,
                overwrite   = true,
                usesaved    = false,
                script      = "\$(Pkg.dir(pkg))/benchmark/benchmarks.jl"
                require     = "\$(Pkg.dir(pkg))/benchmark/REQUIRE",
                tunefile    = "\$(Pkg.dir())/.benchmarks/\$(pkg)/results",
                resultsdir  = "\$(Pkg.dir())/.benchmarks/\$(pkg)/.tune.jld")

Run a benchmark on the package `pkg` using the [`BenchmarkConfig`](@ref) (or git identifier) `target` 
and return `results` which is an instance of a [`BenchmarkResults`](@ref).

**Keyword arguments**:

* `saveresults` - If set to false, results will not be saved in `resultsdir`.
* `usesaved` - If a previously saved result for `target` is found, use that instead of rerunning the benchmarks.
* `retune` - Force a re-tune, saving the new tuning to the tune file
* `overwrite` - Overwrite the result file if it already exists
* `script` - The script with the benchmark.
* `require` - The REQUIRE file containing dependencies needed for the benchmark.
* `tunefile` - File to use for tuning benchmarks, will be created if doesn't exist. Defaults to `PKG/benchmark/.tune.jld`
*  `resultsdir` - The directory where to file away results.

Provided the repository is not dirty, results generated will be saved in this directory in a file, named using a hash based on
the package commit, the julia commit, etc. **Note that the content of the benchmarks script is not included in this hash**.
The result can later by functions such as [`judge`](@ref). If you choose to, you can save the results manually using
[`writeresults(file, results)`](@ref) where `results` is the return value of this function. It can be read back with [`readresults(file)`](@ref).

**Example invocations:**

```julia
using PkgBenchmark

benchmarkpkg("MyPkg") # run the benchmarks at the current state of the repository
benchmarkpkg("MyPkg", "my-feature") # run the benchmarks for a particular branch/commit/tag
benchmarkpkg("MyPkg", "my-feature"; script="/home/me/mycustombenchmark.jl", resultsdir="/home/me/benchmarkXresults")
  # note: its a good idea to set a new resultsdir with a new benchmark script.
  # `PKG/benchmark/.results` is meant for `PKG/benchmark/benchmarks.jl` script.
benchmarkpkg("MyPkg", BenchmarkConfig(id = "my-feature", 
                                      env = Dict("JULIA_NUM_THREADS" => 4),
                                      juliacmd = `julia -O3`))
```
"""
function benchmarkpkg(pkg, target=BenchmarkConfig();
                      script=defaultscript(pkg),
                      require=defaultrequire(pkg),
                      resultsdir=defaultresultsdir(pkg),
                      tunefile=defaulttunefile(pkg),
                      retune=false,
                      usesaved=false,
                      saveresults=true,
                      overwrite=true,
                      custom_loadpath="", #= used in tests =#
                      promptsave=nothing)
    target = BenchmarkConfig(target)
    promptsave != nothing && Base.warn_once("the `promptsave` keyword is deprecated and will be removed.")
    !isfile(script) && error("Benchmark script $script not found")
    dirty = LibGit2.with(LibGit2.isdirty, LibGit2.GitRepo(Pkg.dir(pkg)))
    original_sha = _shastring(Pkg.dir(pkg), "HEAD")
    
    # In this function the package is at the commit we want to benchmark
    function do_benchmark()
        foundfile = false
        pkgsha = _shastring(Pkg.dir(pkg), "HEAD")        
        if ((target.id == nothing && !dirty) || target.id !== nothing) && usesaved
            juliasha = _get_julia_commit(target)
            file = joinpath(resultsdir, string(_hash(pkg, pkgsha, juliasha, target)) * ".jld")
            if isfile(file)
                foundfile = true
                _benchinfo("Found existing result in $resultsdir, using it.   ")
                results = readresults(file)
            end
        end
        if !foundfile 
            # Need to redefine pkgsha here for some reason...
            results_local = _with_reqs(require, () -> info("Resolving dependencies for benchmark")) do
                _withtemp(tempname()) do f
                    _benchinfo("Running benchmarks...")
                    _runbenchmark(script, f, target, tunefile; retune=retune, custom_loadpath = custom_loadpath)
                end
            end
            resgroup, juliasha, vinfo = results_local["results"], results_local["juliasha"], results_local["vinfo"]
            results = BenchmarkResults(pkg, dirty ? "dirty" : pkgsha, resgroup, now(), juliasha, vinfo, target)
        end

        return results
    end

    if target.id !== nothing
        if dirty
            error("$(Pkg.dir(pkg)) is dirty. Please commit/stash your " *
                  "changes before benchmarking a specific commit")
        end
        results = _withcommit(do_benchmark, LibGit2.GitRepo(Pkg.dir(pkg)), target.id)
    else
        # benchmark on the current state of the repo
        results = do_benchmark()
    end

    if !dirty
        if saveresults
            tosave = true
            if promptsave == true
                print("File results of this run?, resultsdir=$resultsdir) (Y/n) ")
                response = string(readline())
                tosave = if response == "" || lowercase(response) == "y"
                    true
                else
                    false
                end
            end
            if tosave
                !isdir(resultsdir) && mkpath(resultsdir)
                resfile = joinpath(resultsdir, string(_hash(results.name, results.commit, results.julia_commit, target)) * ".jld")
                if !isfile(resfile) || overwrite == true
                    writeresults(resfile, results)
                    _benchinfo("Results of the benchmark were written to $resfile")
                elseif !usesaved
                    _benchinfo("Found existing results, no output written")
                end
            end
        end
    else
        _benchwarn("$(Pkg.dir(pkg)) is dirty, not attempting to file results...")
    end
    after_sha = _shastring(Pkg.dir(pkg), "HEAD")

    if original_sha != after_sha
        pkgwarn("Failed to return back to original sha $original_sha, package now at $after_sha")
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
    return load(File(format"JLD", output))
end

function _runbenchmark_local(file, output, tunefile, retune)
    # Loading
    _reset_stack()
    include(file)
    suite = if isdefined(Main, :SUITE)
        Main.SUITE
    else
        _root_group()
    end

    # Tuning
    if isfile(tunefile) && !retune
        _benchinfo("Using benchmark tuning data in $tunefile")
        loadparams!(suite, JLD.load(tunefile, "suite"), :evals, :samples)
    else
        _benchinfo("Creating benchmark tuning file $tunefile")
        mkpath(dirname(tunefile))
        _tune!(suite)
        save(File(format"JLD", tunefile), "suite", params(suite))
    end

    # Running
    results = _run(suite)

    # Output
    vinfo = first(split(readstring(`julia -e 'versioninfo(true)'`), "Environment"))
    juliasha = Base.GIT_VERSION_INFO.commit
    save(File(format"JLD", output), "results", results, "vinfo", vinfo, "juliasha", juliasha)
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

"""
    writeresults(file::String, results::BenchmarkResults)

Writes the [`BenchmarkResults`](@ref) to `file`.
"""
writeresults(file::String, results) = save(File(format"JLD", file), "results", results)


"""
    readresults(file::String)

Reads the [`BenchmarkResults`](@ref) stored in `file` (given as a path).
"""
readresults(file)  = load(File(format"JLD", file))["results"]
