# PkgBenchmarks

Convention and helper functions for package developers to track performance changes in Julia packages.

The package contains the following features:

* A macro based interface, similar to the `Base.Test` interface, to define a suite of benchmarks.
* Running the benchmark suite at a specified commit, branch or tag.
* Comparing performance of a package between different package commits, branches or tags.

## Installation

PkgBenchmark is registered in METADATA so installation is done by running `Pkg.add("PkgBenchmark")`.