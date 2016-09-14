export runbenchmark, benchmarkpkg

import Base.LibGit2: GitRepo, Oid, revparseid

using FileIO
using JLD

function runbenchmark(file::String, output::String)
    benchmark_proc(file, output)
    readresults(output)
end

function benchmark_proc(file, output)
    color = Base.have_color? "--color=yes" : "--color=no"
    compilecache = "--compilecache=" * (Bool(Base.JLOptions().use_compilecache) ? "yes" : "no")
    julia_exe = Base.julia_cmd()
    exec_str =
        """
        using BenchmarkHelper
        BenchmarkHelper.runbenchmark_local("$file", "$output")
        """
    run(`$julia_exe $color $compilecache -e $exec_str`)
end

function runbenchmark_local(file, output)
    _reset_stack()
    include(file)
    results = run(_top_group())
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

function benchmarkpkg(pkg;
                      script=defaultscript(pkg),
                      require=defaultrequire(pkg),
                      resultsdir=defaultresultsdir(pkg),
                      fileresults=true,
                      promptfile=true,
                      promptoverwrite=true)

    !isfile(script) && error("Benchmark script $script not found")
    res = with_reqs(require, ()->info("Resolving dependencies for benchmark")) do
        withtemp(tempname()) do f
            info("Running benchmarks...")
            runbenchmark(script, f)
        end
    end
    dirty = LibGit2.with(LibGit2.isdirty, GitRepo(Pkg.dir(pkg)))
    sha = shastring(Pkg.dir(pkg), "HEAD")
    
    if !dirty
        if fileresults
            tofile = if promptfile
                print("Do you want to file the benchmark results of this run? (commit=$(sha[1:6]), resultsdir=$resultsdir; use writeresults to save manually) (Y/n) ")
                response = readline() |> strip
                response == "" || lowercase(response) == "y"
            else true end
            if tofile
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

function benchmarkpkg(pkg, ref::String; kwargs...)
    LibGit2.with(LibGit2.isdirty, GitRepo(Pkg.dir(pkg))) &&
        error("$(Pkg.dir(pkg)) is dirty. Please commit/stash your " *
              "changes before benchmarking a specific commit")

    LibGit2.with(GitRepo(Pkg.dir(pkg))) do repo
        LibGit2.transact!(repo) do r
            LibGit2.checkout!(r, revparseid(ref))
            benchmarkpkg(pkg; kwargs...)
        end
    end
end

function shastring(dir, refname)
    LibGit2.with(GitRepo(dir)) do r
        string(revparseid(r, refname))
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
