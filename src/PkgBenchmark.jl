__precompile__()

module PkgBenchmark

using BenchmarkTools
using FileIO
using JLD

export benchmarkpkg, judge, @benchgroup, @bench, writeresults, readresults

include("util.jl")
include("macros.jl")
include("benchmarkresults.jl")
include("runbenchmark.jl")
include("judge.jl")

end # module
