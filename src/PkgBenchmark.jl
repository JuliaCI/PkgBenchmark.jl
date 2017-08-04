__precompile__()

module PkgBenchmark

using BenchmarkTools
using FileIO
using JLD
using Compat
using ProgressMeter

export benchmarkpkg, judge, @benchgroup, @bench, writeresults, readresults, export_markdown
export BenchmarkConfig, BenchmarkResults, BenchmarkJudgement

include("macros.jl")
include("benchmarkconfig.jl")
include("benchmarkresults.jl")
include("benchmarkjudgement.jl")
include("runbenchmark.jl")
include("judge.jl")
include("util.jl")

end # module
