# Defining a benchmark suite

## Conventions

- Benchmarks are to be written in `<PKGROOT>/benchmark/benchmarks.jl` and must use the `@benchgroup` and `@bench` macros. These are analogous to `@testset` and `@test` macros, with slightly different syntax.
- `<PKGROOT>/benchmark/REQUIRE` can contain dependencies needed to run the benchmark suite.

## Writing benchmarks

### `@benchgroup`

`@benchgroup` defines a benchmark group. It can contain nested `@benchgroup` and `@bench` expressions.

**Syntax:**

```julia
@benchgroup <name> [<tags>] begin
  <expr>
end
```

`<name>` is a string naming the benchmark group. `<tags>` is a vector of strings, tags for the benchmark group, and is optional. `<expr>` are expressions that can contain `@benchgroup` or `@bench` calls.

### `@bench`

`@bench` creates a benchmark under the current `@benchgroup`.

**Syntax:**

```julia
@bench <name>... <expr>
```

`<name>` is a name/id for the benchmark, the last argument to `@bench`, `<expr>`, is the expression to be benchmarked, and has the same [interpolation features](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#interpolating-values-into-benchmark-expressions) as the `@benchmarkable` macro from BenchmarkTools.

### Example

An example `benchmark/benchmarks.jl` script would look like:

```julia
using PkgBenchmark

@benchgroup "utf8" ["string", "unicode"] begin
    teststr = UTF8String(join(rand(MersenneTwister(1), 'a':'d', 10^4)))
    @bench "replace" replace($teststr, "a", "b")
    @bench "join" join($teststr, $teststr)
end

@benchgroup "trigonometry" ["math", "triangles"] begin
    # nested groups
    @benchgroup "circular" begin
        for f in (sin, cos, tan)
            for x in (0.0, pi)
                
                @bench string(f), x $(f)($x)
            end
        end
    end

    @benchgroup "hyperbolic" begin
        for f in (sinh, cosh, tanh)
            for x in (0.0, pi)
                @bench string(f), x $(f)($x)
            end
        end
    end
end

```

    !!! note
    Running this script directly does not actually run the benchmarks. See the next section._