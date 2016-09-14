
"""
Run a function after loading a REQUIREs file.
Clean up afterwards
"""
function with_reqs(f, reqs::AbstractString)
    if isfile(reqs)
        with_reqs(f, Pkg.Reqs.parse(reqs))
    else
        f()
    end
end

function with_reqs(f, reqs::Dict, pre=()->nothing)
    resolve(merge(Pkg.Reqs.parse("REQUIRE"), reqs))
    try pre(); f() catch ex rethow() finally resolve() end
end

