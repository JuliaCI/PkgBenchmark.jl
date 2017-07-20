__precompile__()

module PkgBenchmark

using BenchmarkTools
using FileIO
using JLD

export benchmarkpkg, judge, @benchgroup, @bench, register_suite

include("util.jl")
include("define_benchmarks.jl")
include("runbenchmark.jl")
include("judge.jl")

end # module
