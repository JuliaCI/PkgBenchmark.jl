# PkgBenchmark

Convention and helper functions for package developers to track performance changes.

```julia
# installation

Pkg.clone("git://github.com/shashi/PkgBenchmark.jl.git")
```

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

_Note that running this script directly does not actually run the benchmarks. See the next section._

## Running a benchmark suite

Use `benchmarkpkg` to run benchmarks written using the convention above.

**Syntax:**

```julia
benchmarkpkg(pkg, [ref];
             script=defaultscript(pkg),
             require=defaultrequire(pkg),
             resultsdir=defaultresultsdir(pkg),
             saveresults=true,
             tunefile=defaulttunefile(pkg),
             retune=false,
             promptsave=true,
             promptoverwrite=true)
```

_Arguments:_

* `pkg` is the package to benchmark
* `ref` is the commit/branch to checkout for benchmarking. If left out, the package will be benchmarked in its current state.

_Keyword arguments:_

* `script` is the script with the benchmarks. Defaults to `PKG/benchmark/benchmarks.jl`
* `require` is the REQUIRE file containing dependencies needed for the benchmark. Defaults to `PKG/benchmark/REQUIRE`.
* `resultsdir` the directory where to file away results. Defaults to `PKG/benchmark/.results`. Provided the repository is not dirty, results generated will be saved in this directory in a file named `<SHA1_of_commit>.jld`. And can be used later by functions such as `judge`. If you choose to, you can save the results manually using `writeresults(file, results)` where `results` is the return value of `benchmarkpkg` function. It can be read back with `readresults(file)`.
* `saveresults` if set to false, results will not be saved in `resultsdir`.
* `promptsave` if set to false, you will prompted to confirm before saving the results.
* `tunefile` file to use for tuning benchmarks, will be created if doesn't exist. Defaults to `PKG/benchmark/.tune.jld`
* `retune` force a re-tune, saving results to the tune file
* `promptsave` if set to false, you will prompted to confirm before saving the results.
* `promptoverwrite` if set to false, will not asked to confirm before overwriting previously saved results for a commit.

_Returns:_

A `BenchmarkGroup` object with the results of the benchmark.

_Example invocations:_

```julia
using PkgBenchmark

benchmarkpkg("MyPkg") # run the benchmarks at the current state of the repository
benchmarkpkg("MyPkg", "my-feature") # run the benchmarks for a particular branch/commit
benchmarkpkg("MyPkg", "my-feature"; script="/home/me/mycustombenchmark.jl", resultsdir="/home/me/benchmarkXresults")
  # note: its a good idea to set a new resultsdir with a new benchmark script. `PKG/benchmark/.results` is meant for `PKG/benchmark/benchmarks.jl` script.
```

## Comparing commits

You can use `judge` to compare benchmark results of two versions of the package.

```julia
judge(pkg, from_ref, [to_ref];
    f=(minimum, minimum),
    usesaved=(true, true),
    script=defaultscript(pkg),
    require=defaultrequire(pkg),
    resultsdir=defaultresultsdir(pkg),
    saveresults=true,
    promptsave=true,
    promptoverwrite=true)
```

Arguments:

- `pkg` is the package to benchmark
- `from_ref` is the base commit / branch
- `to_ref` is the commit to compare against `from_ref`. If omitted, the current state of the code will be used.

Keyword arguments:

- `f` - tuple of estimator functions - one each for `from_ref`, `to_ref` respectively
- `use_saved` - similar tuple of flags, if false will not use saved results
- for description of other keyword arguments, see `benchmarkpkg`

## Bisecting

TODO
