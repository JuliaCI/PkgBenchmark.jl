# PkgBenchmark

*Benchmarking tools for Julia packages*

 [![][docs-stable-img]][docs-stable-url]  [![][travis-img]][travis-url] [![Build status](https://ci.appveyor.com/api/projects/status/p6yg4dukk8oec3be?svg=true)](https://ci.appveyor.com/project/KristofferC/pkgbenchmark-jl) [![Coverage Status][coverage-img]][coverage-url] 

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

## Project Status

The package is tested against Julia `v1.0` to `v1.2` on Linux and macOS.

## Contributing and Questions

Contributions are welcome, as are feature requests and suggestions. Please open an [issue][issues-url] if you encounter any problems.

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://juliaci.github.io/PkgBenchmark.jl/stable

[travis-img]: https://travis-ci.org/JuliaCI/PkgBenchmark.jl.svg?branch=master
[travis-url]: https://travis-ci.org/JuliaCI/PkgBenchmark.jl

[issues-url]: https://github.com/JuliaCI/PkgBenchmark.jl/issues

[coverage-img]: https://coveralls.io/repos/github/JuliaCI/PkgBenchmark.jl/badge.svg?branch=master
[coverage-url]: https://coveralls.io/github/JuliaCI/PkgBenchmark.jl?branch=master
