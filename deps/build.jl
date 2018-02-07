if !isfile(joinpath(@__DIR__, "already_showed"))
    print_with_color(Base.info_color(), STDERR,
    """
    PkgBenchmark has been completely rewritten. Please see https://github.com/JuliaCI/PkgBenchmark.jl/
    for updated documentation and examples. Code written for previous versions of PkgBenchmark is
    unlikely to still work.
    """)
    touch("already_showed")
end