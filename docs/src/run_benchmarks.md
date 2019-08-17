# Running a benchmark suite

```@meta
DocTestSetup  = quote
    using PkgBenchmark
end
```

Use `benchmarkpkg` to run benchmarks defined in a suite as defined in the previous section.

```@docs
benchmarkpkg
```

The results of a benchmark is returned as a `BenchmarkResult`:

```@docs
PkgBenchmark.BenchmarkResults
```

## More advanced customization

Instead of passing a commit, branch etc. as a `String` to `benchmarkpkg`, a [`BenchmarkConfig`](@ref) can be passed

```@docs
PkgBenchmark.BenchmarkConfig
```

This object contains the package commit, julia command, and what environment variables will
be used when benchmarking. The default values can be seen by using the default constructor

```julia-repl
julia> BenchmarkConfig()
BenchmarkConfig:
    id: nothing
    juliacmd: `/home/user/julia/julia`
    env:
```

The `id` is a commit, branch etc as described in the previous section. An `id` with value `nothing` means that the current state of the package will be benchmarked.
The default value of `juliacmd` is `joinpath(Sys.BINDIR, Base.julia_exename()` which is the command to run the julia executable without any command line arguments.

To instead benchmark the branch `PR`, using the julia command `julia -O3`
with the environment variable `JULIA_NUM_THREADS` set to `4`, the config would be created as

```jldoctest
julia> config = BenchmarkConfig(id = "PR",
                                juliacmd = `julia -O3`,
                                env = Dict("JULIA_NUM_THREADS" => 4))
BenchmarkConfig:
    id: "PR"
    juliacmd: `julia -O3`
    env: JULIA_NUM_THREADS => 4
```

To benchmark the package with the config, call [`benchmarkpkg`](@ref) as e.g.

```julia
benchmark("Tensors", config)
```

!!! info
    The `id` keyword to the `BenchmarkConfig` does not have to be a branch, it can be most things that git can understand, for example a commit id
    or a tag.

Benchmarks can be saved and read using `writeresults` and ``readresults` respectively:

```@docs
PkgBenchmark.readresults
PkgBenchmark.writeresults
```