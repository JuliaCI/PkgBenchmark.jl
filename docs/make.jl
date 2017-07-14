using Documenter, PkgBenchmark

makedocs(
    modules = [PkgBenchmark],
    format = :html,
    sitename = "PkgBenchmark.jl",
    pages = Any[
        "Home" => "index.md",
        "Manual" => [
            "man/define_benchmarks.md",
            "man/run_benchmarks.md",
        ]
    ]
)

deploydocs(
    repo = "github.com/JuliaCI/PkgBenchmark.jl.git",
    target = "build",
    julia = "0.6",
    deps = nothing,
    make = nothing
)
