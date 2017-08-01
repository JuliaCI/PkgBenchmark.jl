"""
    judge(pkg::String,
          [ref]::Union{String, BenchmarkConfig},
          baseline::Union{String, BenchmarkConfig};
          f=minimum,
          usesaved=true,
          judgekwargs::Dict{Symbol, Any} = Dict(),
          kwargs...)

**Arguments**:

- `pkg` - The package to benchmark.
- `ref` - What do judge, given as a git id or a [`BenchmarkConfig`](@ref). If skipped, use the current state of the package repo.
- `baseline` - The commit / [`BenchmarkConfig`](@ref) to compare `ref` against.

**Keyword arguments**:

- `f` - Estimator function to use in the [judging](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#trialratio-and-trialjudgement).
- `use_saved::Union{Bool, Tuple{Bool, Bool}}` - If given as a `Bool`, determines if previous saved benchmarks are used for both the `ref` and `baseline`.
   If given as a tuple of `Bool`s, the elements in the tuple are applied to `ref` and `baseline` individually.
- `judgekwargs::Dict{Symbol, Any}` - keyword arguments to pass to the `judge` function in BenchmarkTools
- if saved results are not used or found, the rest of the keyword arguments `kwargs` are passed to [`benchmarkpkg`](@ref)

** Return value **

Returns a [`BenchmarkJudgement`](@ref)
"""
function BenchmarkTools.judge(pkg::String, ref::Union{BenchmarkConfig,String}, baseline::Union{BenchmarkConfig,String};
                              resultsdir=defaultresultsdir(pkg), use_saved::Union{Bool,Tuple{Bool,Bool}}=true,
                              f=minimum, judgekwargs=Dict(), kwargs...)

    ref, baseline = BenchmarkConfig(ref), BenchmarkConfig(baseline)
    use_saved_ref, use_saved_base = (typeof(use_saved) == Tuple{Bool,Bool}) ? use_saved : (use_saved, use_saved)

    function cached(target, _use_saved)
        if target !== nothing && _use_saved
            juliacommit = _get_julia_commit(target)
            pkgcommit = _shastring(Pkg.dir(pkg), target.id == nothing ? "HEAD" : target.id)
            file = joinpath(resultsdir, string(_hash(pkg, pkgcommit, juliacommit, target)) * ".jld")
            if isfile(file)
                _benchinfo("Found existing result for this config in $resultsdir, using it.   ")
                return readresults(file)
            end
        end
        return benchmarkpkg(pkg, target; resultsdir=resultsdir, kwargs...)
    end

    group_ref = cached(ref, use_saved_ref)
    group_baseline = cached(baseline, use_saved_base)

    return judge(group_ref, group_baseline, f; judgekwargs=judgekwargs)
end

function BenchmarkTools.judge(pkg::String, baseline::Union{BenchmarkConfig,String}; kwargs...)
    judge(pkg, BenchmarkConfig(), baseline; kwargs...)
end

"""
    judge(ref::BenchmarkResults, baseline::BenchmarkResults, f;
          judgekwargs = Dict())

Judges the two benchmarkresults in `ref` and `baseline` using the function `f`.
"""
function BenchmarkTools.judge(ref::BenchmarkResults, baseline::BenchmarkResults, f = minimum; judgekwargs = Dict())
    judged = judge(f(benchmarkgroup(ref)), f(benchmarkgroup(baseline)); judgekwargs...)
    return BenchmarkJudgement(
        ref, baseline, judged
    )
end