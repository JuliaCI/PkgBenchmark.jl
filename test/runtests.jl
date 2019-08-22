using PkgBenchmark
using BenchmarkTools
using Statistics
using Test
using Dates
using LibGit2
using Random
using Pkg

const BENCHMARK_DIR = joinpath(@__DIR__, "..", "benchmark")

function temp_pkg_dir(fn::Function; tmp_dir=joinpath(tempdir(), randstring()),
        remove_tmp_dir::Bool=true, initialize::Bool=true)
    # Used in tests below to set up and tear down a sandboxed package directory
    try
        # TODO(nhdaly): Is this right??
        Pkg.activate(tmp_dir)
        Pkg.instantiate()
        fn()
    finally
        # TODO(nhdaly): Is there a way to re-activate the previous environment?
        Pkg.activate()
        remove_tmp_dir && try rm(tmp_dir, recursive=true) catch end
    end
end

function test_structure(g)
    @test g |> keys |> collect |> Set == ["utf8", "trigonometry"] |> Set
    @test g["utf8"] |> keys |> collect |> Set == ["join", "plots", "replace"] |> Set

    _keys = Set(vec([string((string(f), x)) for x in (0.0, pi), f in (sin, cos, tan)]))
    @test g["trigonometry"]["circular"] |> keys |> collect |> Set == _keys
end

@testset "structure" begin
    results = benchmarkpkg("PkgBenchmark")
    test_structure(PkgBenchmark.benchmarkgroup(results))
    @test PkgBenchmark.name(results) == "PkgBenchmark"
    @test Dates.Year(PkgBenchmark.date(results)) == Dates.Year(now())
    export_markdown(stdout, results)
end

const TEST_PACKAGE_NAME = "Example"

# Set up a test package in a temp folder that we use to test things on
tmp_dir = joinpath(tempdir(), randstring())
old_pkgdir = Pkg.depots()[1]

temp_pkg_dir(;tmp_dir = tmp_dir) do
    test_sig = LibGit2.Signature("TEST", "TEST@TEST.COM", round(time(); digits=0), 0)
    full_repo_path = joinpath(tmp_dir, TEST_PACKAGE_NAME)
    Pkg.generate(full_repo_path)
    Pkg.develop(PackageSpec(path=full_repo_path))

    @testset "benchmarkconfig" begin
        PkgBenchmark._withtemp(tempname()) do f
            str = """
            using BenchmarkTools
            using Test
            SUITE = BenchmarkGroup()
            SUITE["foo"] = @benchmarkable 1+1

            @test Base.JLOptions().opt_level == 3
            @test ENV["JL_PKGBENCHMARK_TEST_ENV"] == "10"
            """
            open(f, "w") do file
                print(file, str)
            end

            config = BenchmarkConfig(juliacmd = `$(joinpath(Sys.BINDIR, Base.julia_exename())) -O3`,
            env = Dict("JL_PKGBENCHMARK_TEST_ENV" => 10))
            @test typeof(benchmarkpkg(TEST_PACKAGE_NAME, config, script=f; custom_loadpath=old_pkgdir)) == BenchmarkResults
        end
    end

    @testset "postprocess" begin
        PkgBenchmark._withtemp(tempname()) do f
            str = """
            using BenchmarkTools
            SUITE = BenchmarkGroup()
            SUITE["foo"] = @benchmarkable for _ in 1:100; 1+1; end
            """
            open(f, "w") do file
                print(file, str)
            end
            @test typeof(benchmarkpkg(TEST_PACKAGE_NAME, script=f;
                postprocess=(r)->(r["foo"] = maximum(r["foo"]); return r))) == BenchmarkResults
        end
    end

    # Make a commit with a small benchmarks.jl file
    testpkg_path = Pkg.dir(TEST_PACKAGE_NAME)
    LibGit2.init(testpkg_path)
    repo = LibGit2.GitRepo(testpkg_path)
    initial_commit = LibGit2.commit(repo, "Initial Commit"; author=test_sig, committer=test_sig)
    LibGit2.branch!(repo, "master")


    mkpath(joinpath(testpkg_path, "benchmark"))

    # Make a small example benchmark file
    open(joinpath(testpkg_path, "benchmark", "benchmarks.jl"), "w") do f
        print(f,
        """
            using BenchmarkTools
            SUITE = BenchmarkGroup()
            SUITE["trig"] = BenchmarkGroup()
            SUITE["trig"]["sin"] = @benchmarkable sin(2.0)
        """)
    end

    LibGit2.add!(repo, "benchmark/benchmarks.jl")
    commit_master = LibGit2.commit(repo, "test"; author=test_sig, committer=test_sig)

    @testset "getting back original commit / branch" begin
        # Test we are on a branch and run benchmark on a commit that we end up back on the branch
        LibGit2.branch!(repo, "PR")
        touch(joinpath(testpkg_path, "foo"))
        LibGit2.add!(repo, "foo")
        commit_PR = LibGit2.commit(repo, "PR commit"; author=test_sig, committer=test_sig)
        LibGit2.branch!(repo, "master")
        PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "PR"; custom_loadpath=old_pkgdir)
        @test LibGit2.branch(repo) == "master"

        # Test we are on a commit and run benchmark on another commit and end up on the commit
        LibGit2.checkout!(repo, string(commit_master))
        PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "PR"; custom_loadpath=old_pkgdir)
        @test LibGit2.revparseid(repo, "HEAD") == commit_master
    end

    tmp = tempname() * ".json"

    # Benchmark dirty repo
    cp(joinpath(@__DIR__, "..", "benchmark", "benchmarks.jl"), joinpath(testpkg_path, "benchmark", "benchmarks.jl"); force=true)
    LibGit2.add!(repo, "benchmark/benchmarks.jl")
    LibGit2.add!(repo, "benchmark/REQUIRE")
    @test LibGit2.isdirty(repo)
    @test_throws ErrorException PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "HEAD"; custom_loadpath=old_pkgdir)
    results = PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME; custom_loadpath=old_pkgdir, resultfile=tmp)
    test_structure(PkgBenchmark.benchmarkgroup(results))
    @test isfile(tmp)
    rm(tmp)

    # Commit and benchmark non dirty repo
    commitid = LibGit2.commit(repo, "commiting full benchmarks and REQUIRE"; author=test_sig, committer=test_sig)
    @test !LibGit2.isdirty(repo)
    results = PkgBenchmark.benchmarkpkg(TEST_PACKAGE_NAME, "HEAD"; custom_loadpath=old_pkgdir, resultfile=tmp)
    @test PkgBenchmark.commit(results) == string(commitid)
    @test PkgBenchmark.juliacommit(results) == Base.GIT_VERSION_INFO.commit
    test_structure(PkgBenchmark.benchmarkgroup(results))
    @test isfile(tmp)
    r = readresults(tmp)
    @test r.benchmarkgroup == results.benchmarkgroup
    @test r.commit == results.commit
    rm(tmp)

    # Make a dummy commit and test comparing HEAD and HEAD~
    touch(joinpath(testpkg_path, "dummy"))
    LibGit2.add!(repo, "dummy")
    LibGit2.commit(repo, "dummy commit"; author=test_sig, committer=test_sig)

    @testset "judging" begin
        judgement = judge(TEST_PACKAGE_NAME, "HEAD~", "HEAD", custom_loadpath=old_pkgdir)
        test_structure(PkgBenchmark.benchmarkgroup(judgement))
        export_markdown(stdout, judgement)
        export_markdown(stdout, judgement; export_invariants = false)
        export_markdown(stdout, judgement; export_invariants = true)
        judgement = judge(TEST_PACKAGE_NAME, "HEAD", custom_loadpath=old_pkgdir)
        test_structure(PkgBenchmark.benchmarkgroup(judgement))
    end
end
