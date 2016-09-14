function BenchmarkTools.judge(pkg, from_ref, to_ref=nothing;
    f=(minimum, minimum),
    use_saved=(true, true),
    kwargs...)

    r1 = benchmarkpkg(pkg, from_ref)
    r2 = benchmarkpkg(pkg, to_ref)

    judge(f[1](r1), f[2](r2))
end
