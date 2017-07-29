"""
    judge(pkg, [ref], baseline;
        f=minimum,
        usesaved=true,
        judgekwargs::Dict{Symbol, Any} = Dict(),
        kwargs...)

You can call `showall(results)` to see a comparison of all the benchmarks.

**Arguments**:

- `pkg` - The package to benchmark.
- `ref` - The commit to judge. If skipped, use the current state of the package repo.
- `baseline` - The commit to compare `ref` against.

**Keyword arguments**:

- `f` - Estimator function to use in the [judging](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#trialratio-and-trialjudgement).
- `use_saved::Union{Bool, Tuple{Bool, Bool}}` - If given as a `Bool`, determines if previous saved benchmarks are used for both the `ref` and `baseline`.
   If given as a tuple of `Bool`s, the elements in the tuple are applied to `ref` and `baseline` individually.
- `judgekwargs::Dict{Symbol, Any}` - keyword arguments to pass to the `judge` function in BenchmarkTools
- if saved results are not used or found, the rest of the keyword arguments `kwargs` are passed to [`benchmarkpkg`](@ref)
"""
function BenchmarkTools.judge(pkg::String, ref::Union{String,Void}, baseline::String;
                              resultsdir=defaultresultsdir(pkg), use_saved::Union{Bool, Tuple{Bool, Bool}}=true,
                              f=minimum, judgekwargs=Dict(), kwargs...)

    use_saved_ref, use_saved_base = (typeof(use_saved) == Tuple{Bool, Bool}) ? use_saved : (use_saved, use_saved)

    function cached(target, _use_saved)
        if target !== nothing && _use_saved
            sha = shastring(Pkg.dir(pkg), target)
            file = joinpath(resultsdir, sha*".jld")
            if isfile(file)
                info("Reading results for $(sha[1:6]) from $resultsdir")
                return benchmarkgroup(readresults(file))
            end
        end
        return benchmarkgroup(benchmarkpkg(pkg, ref; resultsdir=resultsdir, kwargs...))
    end

    group_ref = cached(ref, use_saved_ref)
    group_baseline = cached(baseline, use_saved_base)

    return judge(f(group_ref), f(group_baseline); judgekwargs...)
end

function BenchmarkTools.judge(pkg::String, baseline::String; kwargs...)
    judge(pkg, nothing, baseline; kwargs...)
end
