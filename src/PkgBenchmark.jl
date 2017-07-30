__precompile__()

module PkgBenchmark

using BenchmarkTools
using FileIO
using JLD
using Compat

export benchmarkpkg, judge, @benchgroup, @bench, writeresults, readresults, export_markdown
export BenchmarkConfig, BenchmarkResults

include("macros.jl")
include("benchmarkconfig.jl")
include("benchmarkresults.jl")
include("runbenchmark.jl")
include("judge.jl")
include("util.jl")

end # module
