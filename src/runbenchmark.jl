function runbenchmark(file::AbstractString, output::AbstractString, tunefile::AbstractString; retune=false, custom_loadpath = nothing)
    color = Base.have_color? "--color=yes" : "--color=no"
    compilecache = "--compilecache=" * (Bool(Base.JLOptions().use_compilecache) ? "yes" : "no")
    julia_exe = Base.julia_cmd()
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
    run(`$julia_exe $color --code-coverage=$coverage $compilecache -e $exec_str`)
    readresults(output)
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
    if isfile(tune_file) && !retune
        println("Using benchmark tuning data in $tune_file")
        loadparams!(suite, JLD.load(tune_file, "suite"), :evals, :samples)
    else
        println("Creating benchmark tuning file $tune_file")
        mkpath(dirname(tune_file))
        tune!(suite)
        JLD.save(tune_file, "suite", params(suite))
    end

    # Running
    results = run(suite)

    # Output
    writeresults(output, results)
    results
end

# Package benchmarking API

defaultscript(pkg)     = Pkg.dir(pkg, "benchmark", "benchmarks.jl")
defaultrequire(pkg)    = Pkg.dir(pkg, "benchmark", "REQUIRE")
defaultresultsdir(pkg) = Pkg.dir(".benchmarks", pkg, "results")
defaulttunefile(pkg)   = Pkg.dir(".benchmarks", pkg, ".tune.jld")

"""
    benchmarkpkg(pkg, [ref];
                script=defaultscript(pkg),
                require=defaultrequire(pkg),
                resultsdir=defaultresultsdir(pkg),
                saveresults=true,
                tunefile=defaulttunefile(pkg),
                retune=false,
                overwrite=true)

**Arguments**:

* `pkg` is the package to benchmark
* `ref` is the commit/branch to checkout for benchmarking. If left out, the package will be benchmarked in its current state.

**Keyword arguments**:

* `script` is the script with the benchmarks. Defaults to `PKG/benchmark/benchmarks.jl`
* `require` is the REQUIRE file containing dependencies needed for the benchmark. Defaults to `PKG/benchmark/REQUIRE`.
* `resultsdir` the directory where to file away results. Defaults to `PKG/benchmark/.results`. Provided the repository is not dirty, results generated will be saved in this directory in a file named `<SHA1_of_commit>.jld`. And can be used later by functions such as `judge`. If you choose to, you can save the results manually using `writeresults(file, results)` where `results` is the return value of `benchmarkpkg` function. It can be read back with `readresults(file)`.
* `saveresults` if set to false, results will not be saved in `resultsdir`.
* `tunefile` file to use for tuning benchmarks, will be created if doesn't exist. Defaults to `PKG/benchmark/.tune.jld`
* `retune` force a re-tune, saving results to the tune file
* `overwrite` overwrites the result file if it already exists

**Returns:**

A `BenchmarkGroup` object with the results of the benchmark.

**Example invocations:**

```julia
using PkgBenchmark

benchmarkpkg("MyPkg") # run the benchmarks at the current state of the repository
benchmarkpkg("MyPkg", "my-feature") # run the benchmarks for a particular branch/commit/tag
benchmarkpkg("MyPkg", "my-feature"; script="/home/me/mycustombenchmark.jl", resultsdir="/home/me/benchmarkXresults")
  # note: its a good idea to set a new resultsdir with a new benchmark script. `PKG/benchmark/.results` is meant for `PKG/benchmark/benchmarks.jl` script.
```
"""
function benchmarkpkg(pkg, ref=nothing;
                      script=defaultscript(pkg),
                      require=defaultrequire(pkg),
                      resultsdir=defaultresultsdir(pkg),
                      tunefile=defaulttunefile(pkg),
                      retune=false,
                      saveresults=true,
                      overwrite=true,
                      custom_loadpath="", #= used in tests =#
                      promptsave=nothing  #= deprecated =#)

    promptsave != nothing && Base.warn_once("the `promptsave` keyword is deprecated and will be removed.")

    function do_benchmark()
        !isfile(script) && error("Benchmark script $script not found")

        res = with_reqs(require, ()->info("Resolving dependencies for benchmark")) do
            withtemp(tempname()) do f
                info("Running benchmarks...")
                runbenchmark(script, f, tunefile; retune=retune, custom_loadpath = custom_loadpath)
            end
        end

        dirty = LibGit2.with(LibGit2.isdirty, LibGit2.GitRepo(Pkg.dir(pkg)))
        sha = shastring(Pkg.dir(pkg), "HEAD")

        if !dirty
            if saveresults
                tosave = true
                if promptsave == true
                    print("File results of this run? (commit=$(sha[1:6]), resultsdir=$resultsdir) (Y/n) ")
                    response = string(readline())
                    tosave = if response == "" || lowercase(response) == "y"
                        true
                    else
                        false
                    end
                end
                if tosave
                    !isdir(resultsdir) && mkpath(resultsdir)
                    resfile = joinpath(resultsdir, sha*".jld")
                    if !isfile(resfile) || overwrite == true
                        writeresults(resfile, res)
                        info("Results of the benchmark were written to $resfile")
                    else
                        info("Found existing results, no output written")
                    end
                end
            end
        else
            warn("$(Pkg.dir(pkg)) is dirty, not attempting to file results...")
        end

        res
    end

    if ref !== nothing
        if LibGit2.with(LibGit2.isdirty, LibGit2.GitRepo(Pkg.dir(pkg)))
            error("$(Pkg.dir(pkg)) is dirty. Please commit/stash your " *
                  "changes before benchmarking a specific commit")
        end

        return withcommit(do_benchmark, LibGit2.GitRepo(Pkg.dir(pkg)), ref)
    else
        # benchmark on the current state of the repo
        do_benchmark()
    end

end

function writeresults(file, res)
    save(File(format"JLD", file), "time", time(), "trials", res)
end

function readresults(file)
    JLD.jldopen(file,"r") do f
        read(f, "trials")
    end
end
