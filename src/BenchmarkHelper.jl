module BenchmarkHelper

export runbenchmark, judge, bisect

using BenchmarkTools

include("util.jl")
include("macros.jl")
include("runbenchmark.jl")

end # module
