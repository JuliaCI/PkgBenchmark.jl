__precompile__()

module PkgBenchmark

using BenchmarkTools
using JSON
using ProgressMeter
using Pkg
using LibGit2
using Dates
using InteractiveUtils
using Printf

export benchmarkpkg, judge, writeresults, readresults, export_markdown
export BenchmarkConfig, BenchmarkResults, BenchmarkJudgement

include("benchmarkconfig.jl")
include("benchmarkresults.jl")
include("benchmarkjudgement.jl")
include("runbenchmark.jl")
include("judge.jl")
include("util.jl")

end # module
