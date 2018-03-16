__precompile__()

module PkgBenchmark

using BenchmarkTools
using JSON
using ProgressMeter
import Base.DataFmt: writecsv

export benchmarkpkg, judge, writeresults, readresults, export_markdown
export writecsv
export BenchmarkConfig, BenchmarkResults, BenchmarkJudgement

include("benchmarkconfig.jl")
include("benchmarkresults.jl")
include("benchmarkjudgement.jl")
include("runbenchmark.jl")
include("judge.jl")
include("util.jl")

end # module
