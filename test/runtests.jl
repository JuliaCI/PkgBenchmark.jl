using PkgBenchmark
using BenchmarkTools
using Base.Test

import Base.LibGit2: GitRepo

g = BenchmarkGroup()

function test_structure(g)
    @test g |> keys |> collect |> Set == ["utf8", "trigonometry"] |> Set
    @test g["utf8"] |> keys |> collect |> Set == ["join","plots","replace"] |> Set
    @test g["utf8"]["plots"] |> keys |> collect == ["fnplot"]

    _keys = Set([(string(f), x) for x in (0.0, pi), f in (sin, cos, tan)])
    @test g["trigonometry"]["circular"] |> keys |> collect |> Set == _keys
end

@testset "structure" begin
    include(Pkg.dir("PkgBenchmark", "benchmark", "benchmarks.jl"))
    g = PkgBenchmark._top_group()
    test_structure(g)
end

@testset "run benchmarks" begin
    tmp = tempname()
    # TODO: test both cases
    id = LibGit2.revparseid(GitRepo(Pkg.dir("PkgBenchmark")), "HEAD")|>string
    resfile = joinpath(tmp, "$id.jld")
    if !LibGit2.isdirty(GitRepo(Pkg.dir("PkgBenchmark")))
        results = PkgBenchmark.benchmarkpkg("PkgBenchmark", "HEAD"; promptsave=false, resultsdir=tmp)
        test_structure(results)

        @test isfile(resfile)
        @test PkgBenchmark.readresults(resfile) == results
    else
        @test_throws ErrorException PkgBenchmark.benchmarkpkg("PkgBenchmark", "HEAD")
        results = PkgBenchmark.benchmarkpkg("PkgBenchmark"; resultsdir=tmp)
        test_structure(results)
        @test !isfile(resfile)
    end
end

@testset "withresults" begin
    if !LibGit2.isdirty(GitRepo(Pkg.dir("PkgBenchmark")))
        withresults("PkgBenchmark", ["HEAD~", "HEAD"], promptsave=false) do res
            @test length(res) == 2
            a,b=res
            test_structure(a)
            test_structure(b)
            test_structure(judge(minimum(a),minimum(b)))
        end
    end
    # make sure it doesn't error out
end

# Build the docs
makepath = joinpath(dirname(@__FILE__), "..", "docs", "make.jl")
@show readdir(joinpath(dirname(@__FILE__), ".."))
@show readdir(joinpath(dirname(@__FILE__), "..", "docs"))
@show isfile(makepath)

include(joinpath(dirname(@__FILE__), "..", "docs", "make.jl"))