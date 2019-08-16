using Documenter, PkgBenchmark

makedocs(
    modules = [PkgBenchmark],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "PkgBenchmark.jl",
    pages = Any[
        "Home" => "index.md",
        "define_benchmarks.md",
        "run_benchmarks.md",
        "comparing_commits.md",
        "export_markdown.md",
    ]
)

deploydocs(
    repo = "github.com/JuliaCI/PkgBenchmark.jl.git",
)
