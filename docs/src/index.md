# PkgBenchmarks

PkgBenchmark provides an interface for Julia package developers to track performance changes of their packages.

The package contains the following features

* A macro based interface, similar to the `Base.Test` interface, to define a suite of benchmarks. It is, however, also possible to use the dictionary based interface defined in [BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl) in which case it isn't even needed to depend on this package to write the benchmar suite.
* Running the benchmark suite at a specified commit, branch or tag. The path to the julia executable, the command line flags, and the environment variables can be customized.
* Comparing performance of a package between different package commits, branches or tags.
* Exporting results to markdown for benchmarks and comparisons, similar to how Nanosoldier reports results for the benchmarks on Base Julia.

## Installation

PkgBenchmark is registered in METADATA so installation is done by running `Pkg.add("PkgBenchmark")`.