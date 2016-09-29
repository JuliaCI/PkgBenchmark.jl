export runbenchmark, benchmarkpkg

import Base.LibGit2: GitRepo, Oid, revparseid

using FileIO
using JLD

function runbenchmark(file::String, output::String, tunefile::String; retune=false)
    benchmark_proc(file, output, tunefile, retune=retune)
    readresults(output)
end

function benchmark_proc(file, output, tunefile; retune=false)
    color = Base.have_color? "--color=yes" : "--color=no"
    compilecache = "--compilecache=" * (Bool(Base.JLOptions().use_compilecache) ? "yes" : "no")
    julia_exe = Base.julia_cmd()
    exec_str =
        """
        using PkgBenchmark
        PkgBenchmark.runbenchmark_local("$file", "$output", "$tunefile", $retune )
        """
    run(`$julia_exe $color $compilecache -e $exec_str`)
end

function runbenchmark_local(file, output, tunefile, retune)
    _reset_stack()
    include(file)
    suite = root_group()
    cached_tune(tunefile, suite, retune)
    results = run(suite)
    writeresults(output, results)
    results
end

function withtemp(f, file)
    try f(file)
    catch err
        rethrow()
    finally rm(file) end
end

# Package benchmarking API

defaultscript(pkg) =
    Pkg.dir(pkg, "benchmark", "benchmarks.jl")
defaultresultsdir(pkg) =
    Pkg.dir(pkg, "benchmark", ".results")
defaultrequire(pkg) =
    Pkg.dir(pkg, "benchmark", "REQUIRE")
defaulttunefile(pkg) =
    Pkg.dir(pkg, "benchmark", ".tune.jld")

function benchmarkpkg(pkg, ref=nothing;
                      script=defaultscript(pkg),
                      require=defaultrequire(pkg),
                      resultsdir=defaultresultsdir(pkg),
                      tunefile=defaulttunefile(pkg),
                      retune=false,
                      saveresults=true,
                      promptsave=true,
                      promptoverwrite=true)

    function do_benchmark()
        !isfile(script) && error("Benchmark script $script not found")

        res = with_reqs(require, ()->info("Resolving dependencies for benchmark")) do
            withtemp(tempname()) do f
                info("Running benchmarks...")
                runbenchmark(script, f, tunefile; retune=retune)
            end
        end

        dirty = LibGit2.with(LibGit2.isdirty, GitRepo(Pkg.dir(pkg)))
        sha = shastring(Pkg.dir(pkg), "HEAD")

        if !dirty
            if saveresults
                tosave = if promptsave
                    print("File results of this run? (commit=$(sha[1:6]), resultsdir=$resultsdir) (Y/n) ")
                    response = readline() |> strip
                    response == "" || lowercase(response) == "y"
                else true end
                if tosave
                    !isdir(resultsdir) && mkdir(resultsdir)
                    resfile = joinpath(resultsdir, sha*".jld")
                    writeresults(resfile, res)
                    info("Results of the benchmark were written to $resfile")
                end
            end
        else
            warn("$(Pkg.dir(pkg)) is dirty, not attempting to file results...")
        end

        res
    end

    if ref !== nothing
        if LibGit2.with(LibGit2.isdirty, GitRepo(Pkg.dir(pkg)))
            error("$(Pkg.dir(pkg)) is dirty. Please commit/stash your " *
                  "changes before benchmarking a specific commit")
        end

        return withcommit(do_benchmark, GitRepo(Pkg.dir(pkg)), ref)
    else
        # benchmark on the current state of the repo
        do_benchmark()
    end

end

function withcommit(f, repo, commit)
    LibGit2.transact(repo) do r
        branch = try LibGit2.branch(r) catch err; nothing end
        prev = shastring(r, "HEAD")
        try
            LibGit2.checkout!(r, shastring(r,commit))
            f()
        catch err
            rethrow(err)
        finally
            if branch !== nothing
                LibGit2.branch!(r, branch)
            end
        end
    end
end

shastring(r::GitRepo, refname) = string(revparseid(r, refname))
shastring(dir::String, refname) = LibGit2.with(r->shastring(r, refname), GitRepo(dir))

function writeresults(file, res)
    save(File(format"JLD", file), "time", time(), "trials", res)
end

function readresults(file)
    JLD.jldopen(file,"r") do f
        read(f, "trials")
    end
end

function cached_tune(tune_file, suite, force)
    if isfile(tune_file) && !force
       println("Using benchmark tuning data in $tune_file")
       loadparams!(suite, JLD.load(tune_file, "suite"), :evals, :samples)
    else
       println("Creating benchmark tuning file $tune_file")
       tune!(suite)
       JLD.save(tune_file, "suite", params(suite))
    end
    suite
end
