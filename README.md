# BenchmarkHelper

Convention and helper functions for package developers to track performance changes.

```julia
Pkg.clone("git://github.com/shashi/BenchmarkHelper.jl.git")
```

## Convention and macro sugar

Benchmarks are to be defined in `<PKGROOT>/benchmark/benchmarks.jl`, using the `@benchgroup` and `@bench` macros.

**`@benchgroup`**

Creates a benchmark group. Can have nested `@benchgroup` expressions and `@bench` expressions.

Syntax:

```julia
@benchgroup <name> [<tags>] begin
  <expr>
end
```

`<name>` is a string naming the benchmark group. `<tags>` is a vector of strings, tags for the benchmark group, and is optional. `<expr>` are expressions that can contain `@benchgroup` or `@bench` calls.

**`@bench`**

A single benchmark

Syntax:

```julia
@bench <name>... <expr>
```

`<name>` is a name/id for the benchmark, the last argument to `@bench`, `<expr>`, is the expression to be benchmarked, and has the same [interpolation features](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#interpolating-values-into-benchmark-expressions) as the `@benchmarkable` macro from BenchmarkTools.

An example `benchmark/benchmarks.jl` script would look like:

```julia
using BenchmarkHelper

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
                
                @bench string(f) x $(f)($x)
            end
        end
    end

    @benchgroup "hyperbolic" begin
        for f in (sinh, cosh, tanh)
            for x in (0.0, pi)
                @bench string(f) x $(f)($x)
            end
        end
    end
end

```

Note that running the script directly does not actually run the benchmarks. See the next section.

## Running a benchmark

Use `benchmarkpkg` to run benchmarks written using the convention above.

Syntax:

```julia
benchmarkpkg(pkg, [ref];
             script=defaultscript(pkg),
             require=defaultrequire(pkg),
             resultsdir=defaultresultsdir(pkg),
             fileresults=true,
             promptfile=true,
             promptoverwrite=true)
```

Arguments:

* `pkg` is the package to benchmark
* `ref` is the commit/branch to checkout for benchmarking. If left out, the package will be benchmarked in its current state.

Keyword arguments:

* `script` is the script with the benchmarks. Defaults to `PKG/benchmark/benchmarks.jl`
* `require` is the REQUIRE file containing dependencies needed for the benchmark. Defaults to `PKG/benchmark/REQUIRE`.
* `resultsdir` the directory where to file away results. Defaults to `PKG/benchmark/.results`. Provided the repository is not dirty, results generated will be saved in this directory in a file named `<SHA1_of_commit>.jld`. And can be used later by functions such as `compare`. If you choose to, you can save the results manually using `writeresults(file, results)` where `results` is the return value of `benchmarkpkg` function. It can be read back with `readresults(file)`.
* `fileresults` if set to false, results will not be saved in `resultsdir`.
* `promptfile` if set to false, you will prompted to confirm before saving the results.
* `promptoverwrite` if set to false, will not asked to confirm before overwriting previously saved results for a commit.

Returns:

A `BenchmarkGroup` object with the results of the benchmark.

Examples:

```julia
using BenchmarkHelper

benchmarkpkg("MyPkg") # run the benchmarks at the current state of the repository
benchmarkpkg("MyPkg", "my-feature") # run the benchmarks for a particular branch/commit
benchmarkpkg("MyPkg", "my-feature"; script="/home/me/mycustombenchmark.jl", resultsdir="/home/me/benchmarkXresults")
  # note: its a good idea to set a new resultsdir with a new benchmark script. `PKG/benchmark/.results` is meant for `PKG/benchmark/benchmarks.jl` script.
```

## Comparing commits

## Bisecting

