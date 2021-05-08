# PkgBenchmark

*Benchmarking tools for Julia packages*

[![][docs-stable-img]][docs-stable-url]
[![][docs-dev-img]][docs-dev-url]
[![][ci-img]][ci-url]
[![Coveralls][coveralls-img]][coveralls-url]
[![Codecov][codecov-img]][codecov-url]
[![License: MIT](https://img.shields.io/badge/License-MIT-success.svg)](https://opensource.org/licenses/MIT)

## Introduction

PkgBenchmark provides an interface for Julia package developers to track performance changes of their packages.

The package contains the following features:

* Running the benchmark suite at a specified commit, branch or tag. The path to the julia executable, the command line flags, and the environment variables can be customized.
* Comparing performance of a package between different package commits, branches or tags.
* Exporting results to markdown for benchmarks and comparisons, similar to how [Nanosoldier](https://github.com/JuliaCI/Nanosoldier.jl) reports results for the benchmarks on Base Julia.

## Installation

The package is registered and can be installed with `Pkg.add` as

```julia
julia> Pkg.add("PkgBenchmark")
```

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**DEV**][docs-dev-url] &mdash; **most recent development version of the documentation.**

## Project Status

The package is tested against Julia `v1.0` and the latest `v1.x` on Linux, macOS, and Windows.

## Contributing and Questions

Contributions are welcome, as are feature requests and suggestions. Please open an [issue][issues-url] if you encounter any problems.

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://juliaci.github.io/PkgBenchmark.jl/stable

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://juliaci.github.io/PkgBenchmark.jl/dev

[ci-img]: https://github.com/JuliaCI/PkgBenchmark.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/JuliaCI/PkgBenchmark.jl/actions?query=workflow%3ACI

[issues-url]: https://github.com/JuliaCI/PkgBenchmark.jl/issues

[coveralls-img]: https://coveralls.io/repos/github/JuliaCI/PkgBenchmark.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/JuliaCI/PkgBenchmark.jl?branch=master

[codecov-img]: https://codecov.io/gh/JuliaCI/PkgBenchmark.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/JuliaCI/PkgBenchmark.jl
