using BenchmarkHelper
using BenchmarkTools
using Base.Test

import Base.LibGit2: GitRepo

g = BenchmarkGroup()

function test_structure(g)
    @test g |> keys |> collect |> Set == ["utf8", "trigonometry"] |> Set
    @test g["utf8"] |> keys |> collect |> Set == ["join","plots","replace"] |> Set
    @test g["utf8"]["plots"] |> keys |> collect == ["fnplot"]
end

@testset "structure" begin
    include(Pkg.dir("BenchmarkHelper", "benchmark", "benchmarks.jl"))
    g = BenchmarkHelper._top_group()
    test_structure(g)
end

@testset "run benchmarks" begin
    tmp = tempname()
    # TODO: test both cases
    id = LibGit2.revparseid(GitRepo(Pkg.dir("BenchmarkHelper")), "HEAD")|>string
    resfile = joinpath(tmp, "$id.jld")
    if !LibGit2.isdirty(GitRepo(Pkg.dir("BenchmarkHelper")))
        results = BenchmarkHelper.benchmarkpkg("BenchmarkHelper", "HEAD"; promptfile=false, promptoverwrite=false, resultsdir=tmp)
        test_structure(results)

        @test isfile(resfile)
        @test BenchmarkHelper.readresults(resfile) == results
    else
        @test_throws ErrorException BenchmarkHelper.benchmarkpkg("BenchmarkHelper", "HEAD")
        results = BenchmarkHelper.benchmarkpkg("BenchmarkHelper"; resultsdir=tmp)
        test_structure(results)
        @test !isfile(resfile)
    end
end
