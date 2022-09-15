# Defining a benchmark suite

Benchmarks are to be written in `<PKGROOT>/benchmark/benchmarks.jl` and are defined using the standard dictionary based interface from BenchmarkTools, as documented [here](https://juliaci.github.io/BenchmarkTools.jl/dev/manual/#Defining-benchmark-suites). The naming convention that must be used is to name the benchmark suite variable `SUITE`. An example file using the dictionary based interface can be found [here](https://github.com/JuliaCI/PkgBenchmark.jl/blob/master/benchmark/benchmarks.jl). Note that there is no need to have PkgBenchmark loaded to define the benchmark suite.

!!! note
    Running this script directly does not actually run the benchmarks, this is the job of PkgBenchmark, see the next section.
