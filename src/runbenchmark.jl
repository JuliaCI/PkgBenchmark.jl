# Package benchmarking API

defaultscript(pkg)     = Pkg.dir(pkg, "benchmark", "benchmarks.jl")
defaultrequire(pkg)    = Pkg.dir(pkg, "benchmark", "REQUIRE")
defaultresultsdir(pkg) = Pkg.dir(".benchmarks", pkg, "results")
defaulttunefile(pkg)   = Pkg.dir(".benchmarks", pkg, ".tune.jld")

"""
    benchmarkpkg(pkg, [ref]::Union{String, BenchmarkConfig};
                saveresults = true,
                retune      = false,
                overwrite   = true
                script      = "\$(Pkg.dir(pkg))/benchmark/benchmarks.jl"
                require     = "\$(Pkg.dir(pkg))/benchmark/REQUIRE",
                tunefile    = "\$(Pkg.dir())/.benchmarks/\$(pkg)/results",
                resultsdir  = "\$(Pkg.dir())/.benchmarks/\$(pkg)/.tune.jld")

Run a benchmark on the package `pkg` using the [`BenchmarkConfig`](@ref) (or git identifier) `ref` 
and return `results` which is an instance of a [`BenchmarkResults`](@ref).

**Keyword arguments**:

* `script` - The script with the benchmark.
* `require` - The REQUIRE file containing dependencies needed for the benchmark.
* `resultsdir` - The directory where to file away results.
   Provided the repository is not dirty, results generated will be saved in this directory in a file, named using a hash based on
   the package commit, the julia commit, etc.
   The result can later by functions such as `judge`. If you choose to, you can save the results manually using
   [`writeresults(file, results)`](@ref) where `results` is the return value of this function. It can be read back with [`readresults(file)`](@ref).
* `saveresults` - If set to false, results will not be saved in `resultsdir`.
* `tunefile` - File to use for tuning benchmarks, will be created if doesn't exist. Defaults to `PKG/benchmark/.tune.jld`
* `retune` - Force a re-tune, saving the new tuning to the tune file
* `overwrite` - Overwrite the result file if it already exists

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
function benchmarkpkg(pkg, ref=BenchmarkConfig();
                      script=defaultscript(pkg),
                      require=defaultrequire(pkg),
                      resultsdir=defaultresultsdir(pkg),
                      tunefile=defaulttunefile(pkg),
                      retune=false,
                      saveresults=true,
                      overwrite=true,
                      custom_loadpath="", #= used in tests =#
                      promptsave=nothing)
    ref = BenchmarkConfig(ref)
    promptsave != nothing && Base.warn_once("the `promptsave` keyword is deprecated and will be removed.")

    function do_benchmark()
        !isfile(script) && error("Benchmark script $script not found")

        results_local = with_reqs(require, () -> info("Resolving dependencies for benchmark")) do
            withtemp(tempname()) do f
                info("Running benchmarks...")
                runbenchmark(script, f, ref, tunefile; retune=retune, custom_loadpath = custom_loadpath)
            end
        end

        pkgsha = shastring(Pkg.dir(pkg), "HEAD")        

        return results_local, pkgsha
    end

    dirty = LibGit2.with(LibGit2.isdirty, LibGit2.GitRepo(Pkg.dir(pkg)))
    
    if ref.id !== nothing
        if dirty
            error("$(Pkg.dir(pkg)) is dirty. Please commit/stash your " *
                  "changes before benchmarking a specific commit")
        end
        results_local, pkgsha = withcommit(do_benchmark, LibGit2.GitRepo(Pkg.dir(pkg)), ref.id)
    else
        # benchmark on the current state of the repo
        results_local, pkgsha = do_benchmark()
    end

   
    resgroup, juliasha, vinfo = results_local["results"], results_local["juliasha"], results_local["vinfo"]
    results = BenchmarkResults(pkg, dirty ? "dirty" : pkgsha, resgroup, now(), juliasha, vinfo)

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
                resfile = joinpath(resultsdir, string(_hash(pkg, pkgsha, juliasha, ref)) * ".jld")
                if !isfile(resfile) || overwrite == true
                    writeresults(resfile, results)
                    info("Results of the benchmark were written to $resfile")
                else
                    info("Found existing results, no output written")
                end
            end
        end
    else
        warn("$(Pkg.dir(pkg)) is dirty, not attempting to file results...")
    end
    return results
end

function runbenchmark(file::String, output::String, benchmarkconfig::BenchmarkConfig, tunefile::String; 
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
        PkgBenchmark.runbenchmark_local("$_file", "$_output", "$_tunefile", $retune )
        """

    target_env = [k => v for (k, v) in benchmarkconfig.env]
    withenv(target_env...) do
        run(`$(benchmarkconfig.juliacmd) --code-coverage=$coverage $color $compilecache -e $exec_str`)
    end
    return load(File(format"JLD", output))
end

function runbenchmark_local(file, output, tunefile, retune)
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
        println("Using benchmark tuning data in $tunefile")
        loadparams!(suite, JLD.load(tunefile, "suite"), :evals, :samples)
    else
        println("Creating benchmark tuning file $tunefile")
        mkpath(dirname(tunefile))
        tune!(suite)
        save(File(format"JLD", tunefile), "suite", params(suite))
    end

    # Running
    results = run(suite)

    # Output
    vinfo = first(split(readstring(`julia -e 'versioninfo(true)'`), "Environment"))
    juliasha = Base.GIT_VERSION_INFO.commit
    save(File(format"JLD", output), "results", results, "vinfo", vinfo, "juliasha", juliasha)
    return nothing
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