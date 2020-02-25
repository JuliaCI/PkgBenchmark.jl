__precompile__()

module PkgBenchmark

using BenchmarkTools
using JSON
using Pkg
using LibGit2
using Dates
using InteractiveUtils
using Printf
using Logging: with_logger
using TerminalLoggers: TerminalLogger
using UUIDs: UUID

export benchmarkpkg, judge, writeresults, readresults, export_markdown, memory
export BenchmarkConfig, BenchmarkResults, BenchmarkJudgement

include("benchmarkconfig.jl")
include("benchmarkresults.jl")
include("benchmarkjudgement.jl")
include("runbenchmark.jl")
include("judge.jl")
include("util.jl")

end # module
