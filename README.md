# PkgBenchmark

*Benchmarking tools for Julia packages*

| **Documentation**                                                               | **PackageEvaluator**                                                                            | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] [![Coverage Status][coverage-img]][coverage-url] |

## Introduction

PkgBenchmark provides an interface for Julia package developers to track performance changes of their packages.

The package contains the following features

* Running the benchmark suite at a specified commit, branch or tag. The path to the julia executable, the command line flags, and the environment variables can be customized.
* Comparing performance of a package between different package commits, branches or tags.
* Exporting results to markdown for benchmarks and comparisons, similar to how Nanosoldier reports results for the benchmarks on Base Julia.

## Installation

The package is registered and can be installed with `Pkg.add` as

```julia
julia> Pkg.add("PkgBenchmark")
```

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-latest-url] &mdash; *in-development version of the documentation.*

## Project Status

The package is tested against Julia `0.6` on Linux and macOS.

## Contributing and Questions

Contributions are welcome, as are feature requests and suggestions. Please open an [issue][issues-url] if you encounter any problems.


[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://juliaci.github.io/PkgBenchmark.jl/latest/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://juliaci.github.io/PkgBenchmark.jl/stable

[travis-img]: https://travis-ci.org/JuliaCI/PkgBenchmark.jl.svg?branch=master
[travis-url]: https://travis-ci.org/JuliaCI/PkgBenchmark.jl

[issues-url]: https://github.com/JuliaCI/PkgBenchmark.jl/issues

[coverage-img]: https://coveralls.io/repos/github/JuliaCI/PkgBenchmark.jl/badge.svg?branch=master
[coverage-url]: https://coveralls.io/github/JuliaCI/PkgBenchmark.jl?branch=master
