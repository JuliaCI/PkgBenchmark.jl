using PkgBenchmark
using BenchmarkTools
using Base.Test

const BENCHMARK_DIR = joinpath(@__DIR__, "..", "benchmark")

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
            remove_tmp_dir && try rm(tmp_dir, recursive=true) end
        end
    end
end

function test_structure(g)
    @test g |> keys |> collect |> Set == ["utf8", "trigonometry"] |> Set
    @test g["utf8"] |> keys |> collect |> Set == ["join", "plots", "replace"] |> Set
    @test g["utf8"]["plots"] |> keys |> collect == ["fnplot"]

    _keys = Set(vec([string((string(f), x)) for x in (0.0, pi), f in (sin, cos, tan)]))
    @test g["trigonometry"]["circular"] |> keys |> collect |> Set == _keys
end

@testset "structure" begin
    results = benchmarkpkg("PkgBenchmark")
    test_structure(PkgBenchmark.benchmarkgroup(results))
    @test PkgBenchmark.name(results) == "PkgBenchmark"
    @test Dates.Year(PkgBenchmark.date(results)) == Dates.Year(now())
    export_markdown(STDOUT, results)
end

const TEST_PACKAGE_NAME = "Example"

# Set up a test package in a temp folder that we use to test things on
tmp_dir = joinpath(tempdir(), randstring())
old_pkgdir = Pkg.dir()

temp_pkg_dir(;tmp_dir = tmp_dir) do
    test_sig = LibGit2.Signature("TEST", "TEST@TEST.COM", round(time(), 0), 0)
    Pkg.add(TEST_PACKAGE_NAME)

    @testset "benchmarkconfig" begin
        PkgBenchmark._withtemp(tempname()) do f
            str = """
            using BenchmarkTools
            using Base.Test
            SUITE = BenchmarkGroup()
            SUITE["foo"] = @benchmarkable 1+1

            @test Base.JLOptions().opt_level == 3
            @test ENV["JL_PKGBENCHMARK_TEST_ENV"] == "10"
            """
            open(f, "w") do file
                print(file, str)
            end

            config = BenchmarkConfig(juliacmd = `$(joinpath(JULIA_HOME, Base.julia_exename())) -O3`,
                                    env = Dict("JL_PKGBENCHMARK_TEST_ENV" => 10))
            @test typeof(benchmarkpkg(TEST_PACKAGE_NAME, config, script=f; custom_loadpath=old_pkgdir)) == BenchmarkResults
            end
        end

    # Make a commit with a small benchmarks.jl file
    testpkg_path = Pkg.dir(TEST_PACKAGE_NAME)
    repo = LibGit2.GitRepo(testpkg_path)
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
    cp(joinpath(@__DIR__, "..", "benchmark", "benchmarks.jl"), joinpath(testpkg_path, "benchmark", "benchmarks.jl"); remove_destination=true)
    cp(joinpath(@__DIR__, "..", "benchmark", "REQUIRE"), joinpath(testpkg_path, "benchmark", "REQUIRE"))
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

    # Write the benchmark result to a CSV file and check the result
    csvfilename = tempname()
    writecsv(csvfilename, results)
    csvdata = readcsv(csvfilename)
    rm(csvfilename)
    @test size(csvdata) == (16, 9)
    @test csvdata[5, 3] == "(\"tan\", π = 3.1415926535897...)"

    # Make a dummy commit and test comparing HEAD and HEAD~
    touch(joinpath(testpkg_path, "dummy"))
    LibGit2.add!(repo, "dummy")
    LibGit2.commit(repo, "dummy commit"; author=test_sig, committer=test_sig)

    @testset "judging" begin
        judgement = judge(TEST_PACKAGE_NAME, "HEAD~", "HEAD", custom_loadpath=old_pkgdir)
        test_structure(PkgBenchmark.benchmarkgroup(judgement))
        export_markdown(STDOUT, judgement)
        judgement = judge(TEST_PACKAGE_NAME, "HEAD", custom_loadpath=old_pkgdir)
        test_structure(PkgBenchmark.benchmarkgroup(judgement))
        # Write the benchmark result to a CSV file and check the result
        csvfilename = tempname()
        writecsv(csvfilename, judgement)
        csvdata = readcsv(csvfilename)
        rm(csvfilename)
        @test size(csvdata) == (16, 7)
        @test csvdata[5, 3] == "(\"tan\", π = 3.1415926535897...)"
    end
end
