using Documenter, PkgBenchmark

makedocs(
    modules = [PkgBenchmark],
    format = :html,
    sitename = "PkgBenchmark.jl",
    pages = Any[
        "Home" => "index.md",
        "define_benchmarks.md",
        "run_benchmarks.md",
        "comparing_commits.md",
        "export_markdown.md",
        "Reference" => "ref.md",
    ]
)

deploydocs(
    repo = "github.com/JuliaCI/PkgBenchmark.jl.git",
    target = "build",
    julia = "0.6",
    deps = nothing,
    make = nothing
)
