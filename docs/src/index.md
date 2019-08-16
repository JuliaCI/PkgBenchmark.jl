# PkgBenchmarks

PkgBenchmark provides an interface for Julia package developers to track performance changes of their packages.

The package contains the following features

* Running the benchmark suite at a specified commit, branch or tag. The path to the julia executable, the command line flags, and the environment variables can be customized.
* Comparing performance of a package between different package commits, branches or tags.
* Exporting results to markdown for benchmarks and comparisons, similar to how Nanosoldier reports results for the benchmarks in Base Julia.

## Installation

PkgBenchmark is registered so installation is done by running `import Pkg; Pkg.add("PkgBenchmark")`.
