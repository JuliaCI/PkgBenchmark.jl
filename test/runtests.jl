using PkgBenchmark
using BenchmarkTools
using Base.Test

function temp_pkg_dir(fn::Function; tmp_dir=joinpath(tempdir(), randstring()),
        remove_tmp_dir::Bool=true, initialize::Bool=true)
    # Used in tests below to set up and tear down a sandboxed package directory
    withenv("JULIA_PKGDIR" => tmp_dir) do
        @test !isdir(Pkg.dir())
        try
            if initialize
                Pkg.init()
                @test isdir(Pkg.dir())
                Pkg.resolve()
            else
                mkpath(Pkg.dir())
            end
            fn()
        finally
            remove_tmp_dir && rm(tmp_dir, recursive=true)
        end
    end
end

function test_structure(g)
    @test g |> keys |> collect |> Set == ["utf8", "trigonometry"] |> Set
    @test g["utf8"] |> keys |> collect |> Set == ["join", "plots", "replace"] |> Set
    @test g["utf8"]["plots"] |> keys |> collect == ["fnplot"]

    _keys = Set([(string(f), x) for x in (0.0, pi), f in (sin, cos, tan)])
    @test g["trigonometry"]["circular"] |> keys |> collect |> Set == _keys
end


@testset "structure" begin
    @testset "macro" begin
        include(Pkg.dir("PkgBenchmark", "benchmark", "benchmarks.jl"))
        test_structure(PkgBenchmark._top_group())
    end

    @testset "dict" begin
        include(Pkg.dir("PkgBenchmark", "benchmark", "benchmarks_dict.jl"))
        test_structure(PkgBenchmark._get_suite())
    end
end


const TEST_PACKAGE_NAME = "Example"

# Set up a test package in a temp folder that we use to test things on
tmp_dir = joinpath(tempdir(), randstring())
old_pkgdir = Pkg.dir()

temp_pkg_dir(;tmp_dir = tmp_dir) do
    test_sig = LibGit2.Signature("TEST", "TEST@TEST.COM", round(time(), 0), 0)
    Pkg.add(TEST_PACKAGE_NAME)
    testpkg_path = Pkg.dir(TEST_PACKAGE_NAME)
    mkpath(joinpath(testpkg_path, "benchmark"))

    # Make a small example benchmark file
    open(joinpath(testpkg_path, "benchmark", "benchmarks.jl"), "w") do f
        print(f,
        """
            using PkgBenchmark
            @benchgroup "trig" begin
                @bench "sin" sin(2.0)
            end
        """)
    end

    # Make a commit with a small benchmarks.jl file
    repo = LibGit2.GitRepo(testpkg_path)
    LibGit2.add!(repo, "benchmark/benchmarks.jl")
    commit_master = LibGit2.commit(repo, "test"; author=test_sig, committer=test_sig)

    @testset "getting back original commit / branch" begin
        # Test we are on a branch and run benchmark on a commit that we end up back on the branch
        LibGit2.branch!(repo, "PR")
        LibGit2.branch!(repo, "master")
        PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "PR"; custom_loadpath=old_pkgdir)
        @test LibGit2.branch(repo) == "master"

        # Test we are on a commit and run benchmark on another commit and end up on the commit
        LibGit2.checkout!(repo, string(commit_master))
        PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "PR"; custom_loadpath=old_pkgdir)
        @test LibGit2.revparseid(repo, "HEAD") == commit_master
    end

    tmp = tempdir()
    id = string(LibGit2.revparseid(LibGit2.GitRepo(Pkg.dir(TEST_PACKAGE_NAME)), "HEAD"))
    resfile = joinpath(tmp, "$id.jld")

    # Benchmark dirty repo
    cp(joinpath(dirname(@__FILE__), "..", "benchmark", "benchmarks.jl"), joinpath(testpkg_path, "benchmark", "benchmarks.jl"); remove_destination=true)
    cp(joinpath(dirname(@__FILE__), "..", "benchmark", "REQUIRE"), joinpath(testpkg_path, "benchmark", "REQUIRE"))
    LibGit2.add!(repo, "benchmark/benchmarks.jl")
    LibGit2.add!(repo, "benchmark/REQUIRE")
    @test LibGit2.isdirty(repo)
    @test_throws ErrorException PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "HEAD"; custom_loadpath=old_pkgdir)
    results = PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME; custom_loadpath=old_pkgdir, resultsdir=tmp)
    test_structure(results)
    @test !isfile(resfile)

    # Commit and benchmark non dirty repo
    commitid = LibGit2.commit(repo, "commiting full benchmarks and REQUIRE"; author=test_sig, committer=test_sig)
    resfile = joinpath(tmp, "$(string(commitid)).jld")
    @test !LibGit2.isdirty(repo)
    results = PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "HEAD"; custom_loadpath=old_pkgdir, resultsdir=tmp)
    test_structure(results)
    @test isfile(resfile)
    @test PkgBenchmark.readresults(resfile) == results

    # Make a dummy commit and test comparing HEAD and HEAD~
    touch(joinpath(testpkg_path, "dummy"))
    LibGit2.add!(repo, "dummy")
    LibGit2.commit(repo, "dummy commit"; author=test_sig, committer=test_sig)

    @testset "withresults" begin
        PkgBenchmark.withresults(TEST_PACKAGE_NAME, ["HEAD~", "HEAD"], custom_loadpath=old_pkgdir) do res
            @test length(res) == 2
            a, b = res
            test_structure(a)
            test_structure(b)
            test_structure(judge(minimum(a), minimum(b)))
        end
    end
end
