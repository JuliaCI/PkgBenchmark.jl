
function _cached(pkg, ref; resultsdir=defaultresultsdir(pkg), kws...)
    if ref !== nothing
        sha = shastring(Pkg.dir(pkg), ref)
        file = joinpath(resultsdir, sha*".jld")
        if isfile(file)
            info("Reading results for $(sha[1:6]) from $resultsdir")
            return benchmarkgroup(readresults(file))
        end
    end

    benchmarkgroup(benchmarkpkg(pkg, ref;resultsdir=resultsdir, kws...))
end

_repeat(x, n) = !isa(n, AbstractArray) && [x for _ in 1:n]
_repeat(x::AbstractArray, n) = x

function withresults(f::Function, pkg::String, refs;
                     use_saved=trues(length(refs)), kwargs...)

    use_saved = _repeat(use_saved, length(refs))
    [s ? _cached(pkg, r; kwargs...) : benchmarkgroup(benchmarkpkg(pkg, r; kwargs...))
        for (r,s) in zip(refs, use_saved)] |> f
end

"""
    judge(pkg, [ref], baseline;
        f=(minimum, minimum),
        usesaved=(true, true),
        script=defaultscript(pkg),
        require=defaultrequire(pkg),
        resultsdir=defaultresultsdir(pkg),
        saveresults=true,
        promptsave=true,
        promptoverwrite=true)

You can call `showall(results)` to see a comparison of all the benchmarks.

**Arguments**:

- `pkg` is the package to benchmark
- `ref` optional, the commit to judge. If skipped, use the current state of the package repo.
- `baseline` is the commit to compare `ref` against.

**Keyword arguments**:

- `f` - tuple of estimator functions - one each for `from_ref`, `to_ref` respectively
- `use_saved` - similar tuple of flags, if false will not use saved results
- for description of other keyword arguments, see [`benchmarkpkg`](@ref)
"""
function BenchmarkTools.judge(pkg::String, ref1::Union{String,Void}, ref2::String; f=minimum, judgekwargs=Dict(), kwargs...)
    fs = _repeat(f, 2)
    withresults(rs->judge(map((f,x)->f(x), fs, rs)...; judgekwargs...), pkg, (ref1, ref2); kwargs...)
end

function BenchmarkTools.judge(pkg::String, ref2::String; kwargs...)
    judge(pkg, nothing, ref2; kwargs...)
end
