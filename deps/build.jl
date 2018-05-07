if !isfile(joinpath(@__DIR__, "already_showed"))
    printstyled(stderr,
    """
    PkgBenchmark has been completely rewritten. Please see https://github.com/JuliaCI/PkgBenchmark.jl/
    for updated documentation and examples. Code written for previous versions of PkgBenchmark is
    unlikely to still work.
    """; color = Base.info_color())
    touch("already_showed")
end
