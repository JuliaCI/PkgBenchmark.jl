"""
Run a function after loading a REQUIREs file.
Clean up afterwards
"""
function with_reqs(f, reqs::AbstractString, pre=()->nothing)
    if isfile(reqs)
        with_reqs(f, Pkg.Reqs.parse(reqs), pre)
    else
        f()
    end
end

function with_reqs(f, reqs::Dict, pre=()->nothing)
    pre()
    cd(Pkg.dir()) do
        Pkg.Entry.resolve(merge(Pkg.Reqs.parse("REQUIRE"), reqs))
    end
    try f() catch ex rethrow() finally cd(Pkg.Entry.resolve, Pkg.dir()) end
end
