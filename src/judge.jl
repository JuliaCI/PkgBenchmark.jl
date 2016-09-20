export judge, withresults

function _cached(pkg, ref; resultsdir=defaultresultsdir(pkg), kws...)
    sha = shastring(Pkg.dir(pkg), ref)
    file = joinpath(resultsdir, sha*".jld")
    if isfile(file)
        info("Reading results for $(sha[1:6]) from $resultsdir")
        readresults(file)
    else
        benchmarkpkg(pkg, ref;resultsdir=resultsdir, kws...)
    end
end

_repeat(x, n) = !isa(n, AbstractArray) && [x for _ in 1:n]
_repeat(x::AbstractArray, n) = x

function withresults(f::Function, pkg::String, refs;
                                    use_saved=trues(length(refs)), kwargs...)

    use_saved = _repeat(use_saved, length(refs))
    [s ? _cached(pkg, r; kwargs...) : benchmarkpkg(pkg, r; kwargs...)
        for (r,s) in zip(refs, use_saved)] |> f
end

function BenchmarkTools.judge(pkg::String, ref1::String, ref2::String; f=minimum, judgekwargs=Dict(), kwargs...)
    fs = _repeat(f, 2)
    withresults(rs->judge(map((f,x)->f(x), fs, rs)...; judgekwargs...), pkg, (ref1, ref2); kwargs...)
end
