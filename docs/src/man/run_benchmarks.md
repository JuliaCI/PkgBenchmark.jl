# Running a benchmark suite

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

**Arguments**:

* `pkg` is the package to benchmark
* `ref` is the commit/branch to checkout for benchmarking. If left out, the package will be benchmarked in its current state.

**Keyword arguments**:

* `script` is the script with the benchmarks. Defaults to `PKG/benchmark/benchmarks.jl`
* `require` is the REQUIRE file containing dependencies needed for the benchmark. Defaults to `PKG/benchmark/REQUIRE`.
* `resultsdir` the directory where to file away results. Defaults to `PKG/benchmark/.results`. Provided the repository is not dirty, results generated will be saved in this directory in a file named `<SHA1_of_commit>.jld`. And can be used later by functions such as `judge`. If you choose to, you can save the results manually using `writeresults(file, results)` where `results` is the return value of `benchmarkpkg` function. It can be read back with `readresults(file)`.
* `saveresults` if set to false, results will not be saved in `resultsdir`.
* `promptsave` if set to false, you will prompted to confirm before saving the results.
* `tunefile` file to use for tuning benchmarks, will be created if doesn't exist. Defaults to `PKG/benchmark/.tune.jld`
* `retune` force a re-tune, saving results to the tune file
* `promptsave` if set to false, you will prompted to confirm before saving the results.
* `promptoverwrite` if set to false, will not asked to confirm before overwriting previously saved results for a commit.

**Returns:**

A `BenchmarkGroup` object with the results of the benchmark.

**Example invocations:**

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
judge(pkg, [ref], baseline;
    f=(minimum, minimum),
    usesaved=(true, true),
    script=defaultscript(pkg),
    require=defaultrequire(pkg),
    resultsdir=defaultresultsdir(pkg),
    saveresults=true,
    promptsave=true,
    promptoverwrite=true)
```

You can call `showall(results)` to see a comparison of all the benchmarks.

**Arguments**:

- `pkg` is the package to benchmark
- `ref` optional, the commit to judge. If skipped, use the current state of the package repo.
- `baseline` is the commit to compare `ref` against.

**Keyword arguments**:

- `f` - tuple of estimator functions - one each for `from_ref`, `to_ref` respectively
- `use_saved` - similar tuple of flags, if false will not use saved results
- for description of other keyword arguments, see `benchmarkpkg`
