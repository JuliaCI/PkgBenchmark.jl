# Export to markdown

It is possible to export results from [`PkgBenchmark.BenchmarkResults`](@ref) and  [`PkgBenchmark.BenchmarkJudgement`](@ref)  using the function `export_markdown`

```@docs
export_markdown
```

## Using Github.jl to upload the markdown to a Gist

Assuming that we have gotten a `BenchmarkResults` or `BenchmarkJudgement` from a benchmark, we can then use [GitHub.jl](https://github.com/JuliaWeb/GitHub.jl) to programatically upload the exported markdown to a gist:

```julia-repl
julia> using GitHub, JSON, PkgBenchmark

julia> results = benchmarkpkg("PkgBenchmark");

julia> gist_json = JSON.parse(
            """
            {
            "description": "A benchmark for PkgBenchmark",
            "public": false,
            "files": {
                "benchmark.md": {
                "content": "$(escape_string(sprint(export_markdown, results)))"
                }
            }
            }
            """
        )

julia> posted_gist = create_gist(params = gist_json);

julia> url = get(posted_gist.html_url)
URI(https://gist.github.com/317378b4fcf2fb4c5585b104c3b177a8)
```

!!! note
    Consider using an extension to your browser to make the gist webpage use full width in order for the tables
    in the gist to render better, see e.g [here](https://github.com/mdo/github-wide).
