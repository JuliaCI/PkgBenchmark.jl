"""
Stores the results from running the benchmarks on a package.

The following (unexported) methods are defined on a `BenchmarkResults` (written below as `results`):

* `name(results)::String` - the commit of the package benchmarked
* `commit(results)::String` - the commit of the package benchmarked. If the package repository was dirty, the string `"dirty"` is returned.
* `benchmarkgroup(results)::BenchmarkGroup` - a [`BenchmarkGroup`](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#the-benchmarkgroup-type)
   contaning the results of the benchmark.
* `date(results)::DateTime` - the time when the benchmarks were executed
"""
struct BenchmarkResults
    name::String
    commit::String
    benchmarkgroup::BenchmarkGroup
    date::DateTime
end

Base.:(==)(r1::BenchmarkResults, r2::BenchmarkResults) = r1.name           == r2.name           &&
                                                         r1.commit         == r2.commit         &&
                                                         r1.benchmarkgroup == r2.benchmarkgroup &&
                                                         r1.date           == r2.date

name(results::BenchmarkResults) = results.name
commit(results::BenchmarkResults) = results.commit
benchmarkgroup(results::BenchmarkResults) = results.benchmarkgroup
date(results::BenchmarkResults) = results.date

function Base.show(io::IO, results::BenchmarkResults)
    if get(io, :limit, false)
        print(io, "Benchmarkresults for ", results.name)
    else
        print_with_color(:nothing, "Benchmarkresults:\n"; bold = true)
        println(io, "    Package: ", results.name)
        println(io, "    Date: ", Base.Dates.format(results.date, "m u Y - H:M"))
        println(io  , "    Package commit: ", results.commit)
        iob = IOBuffer()
        ioc = IOContext(iob)
        show(ioc, MIME("text/plain"), results.benchmarkgroup)
        println(io,   "    BenchmarkGroup:")
        print(join("        " .* split(String(take!(iob)), "\n"), "\n"))
    end
end
