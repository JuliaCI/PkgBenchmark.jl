"""
    judge(pkg::String,
          [target]::Union{String, BenchmarkConfig},
          baseline::Union{String, BenchmarkConfig};
          kwargs...)

**Arguments**:

- `pkg` - The path to the package to benchmark, use `pathof(Package)`
- `target` - What do judge, given as a git id or a [`BenchmarkConfig`](@ref). If skipped, use the current state of the package repo.
- `baseline` - The commit / [`BenchmarkConfig`](@ref) to compare `target` against.

**Keyword arguments**:

- `f` - Estimator function to use in the [judging](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#trialratio-and-trialjudgement).
- `judgekwargs::Dict{Symbol, Any}` - keyword arguments to pass to the `judge` function in BenchmarkTools

The remaining keyword arguments are passed to [`benchmarkpkg`](@ref)

**Return value**:

Returns a [`BenchmarkJudgement`](@ref)
"""
function BenchmarkTools.judge(pkg::String, target::Union{BenchmarkConfig,String}, baseline::Union{BenchmarkConfig,String};
                              f=minimum, judgekwargs=Dict(), kwargs...)

    target, baseline = BenchmarkConfig(target), BenchmarkConfig(baseline)

    group_target = benchmarkpkg(pkg, target; kwargs...)
    group_baseline = benchmarkpkg(pkg, baseline; kwargs...)

    return judge(group_target, group_baseline, f; judgekwargs=judgekwargs)
end

function BenchmarkTools.judge(pkg::String, baseline::Union{BenchmarkConfig,String}; kwargs...)
    judge(pkg, BenchmarkConfig(), baseline; kwargs...)
end

"""
    judge(target::BenchmarkResults, baseline::BenchmarkResults, f;
          judgekwargs = Dict())

Judges the two [`BenchmarkResults`](@ref) in `target` and `baseline` using the function `f`.

**Return value**

Returns a [`BenchmarkJudgement`](@ref)
"""
function BenchmarkTools.judge(target::BenchmarkResults, baseline::BenchmarkResults, f = minimum; judgekwargs = Dict())
    judged = judge(f(benchmarkgroup(target)), f(benchmarkgroup(baseline)); judgekwargs...)
    return BenchmarkJudgement(target, baseline, judged)
end
