"""
Stores the results from running the benchmarks on a package.

The following (unexported) methods are defined on a `BenchmarkResults` (written below as `results`):

* `name(results)::String` - the commit of the package benchmarked
* `commit(results)::String` - the commit of the package benchmarked. If the package repository was dirty, the string `"dirty"` is returned.
* `benchmarkgroup(results)::BenchmarkGroup` - a [`BenchmarkGroup`](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#the-benchmarkgroup-type)
   contaning the results of the benchmark.
* `date(results)::DateTime` - the time when the benchmarks were executed

`BenchmarkResults` can be exported to markdown using the function [`export_markdown`](@ref).
"""
immutable BenchmarkResults
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
    println("Benchmarkresults:")
    println(io, "    Package: ", results.name)
    println(io, "    Date: ", Base.Dates.format(results.date, "m u Y - H:M"))
    println(io  , "    Package commit: ", results.commit)
    iob = IOBuffer()
    ioc = IOContext(iob)
    show(ioc, MIME("text/plain"), results.benchmarkgroup)
    println(io,   "    BenchmarkGroup:")
    print(join("        " .* split(String(take!(iob)), "\n"), "\n"))
end


"""
    export_markdown(file::String, results::BenchmarkResults)
    export_markdown(io::IO, results::BenchmarkResults)

Writes the `results` to `file` or `io` in markdown format.

See also: [`BenchmarkResults`](@ref)
"""
function export_markdown(file::String, results::BenchmarkResults)
    open(file, "w") do f
        export_markdown(f, results)
    end
end

function export_markdown(io::IO, results::BenchmarkResults)
    println(io, """
                # Benchmark Report for *$(name(results))*
                
                ## Job Properties    
                * Time of benchmark: $(Base.Dates.format(date(results), "m u Y - H:M"))
                * Package commit: $(commit(results)[1:min(6, length(commit(results)))])
                """)

      println(io, """
                ## Results
                Below is a table of this job's results, obtained by running the benchmarks.
                The values listed in the `ID` column have the structure `[parent_group, child_group, ..., key]`, and can be used to 
                index into the BaseBenchmarks suite to retrieve the corresponding benchmarks.
                The percentages accompanying time and memory values in the below table are noise tolerances. The "true"
                time/memory value for a given benchmark is expected to fall within this percentage of the reported value.
                """)

    print(io, """
                | ID | time | GC time | memory | allocations |
                |----|:----:|:-------:|:------:|:-----------:|
                """)

    entries = BenchmarkTools.leaves(benchmarkgroup(results))
    entries = entries[sortperm(map(x -> string(first(x)), entries))]


    for (ids, t) in entries
        println(io, resultrow(ids, t))
    end
    println(io)
    println(io, """
                ## Benchmark Group List
                Here's a list of all the benchmark groups executed by this job:
                """)

    for id in unique(map(pair -> pair[1][1:end-1], entries))
        println(io, "- `", idrepr(id), "`")
    end

    return nothing
end

idrepr(id) = (str = repr(id); str[searchindex(str, '['):end])
intpercent(p) = string(ceil(Int, p * 100), "%")
resultrow(ids, t::BenchmarkTools.Trial) = resultrow(ids, minimum(t))

function resultrow(ids, t::BenchmarkTools.TrialEstimate)
    t_tol = intpercent(BenchmarkTools.params(t).time_tolerance)
    m_tol = intpercent(BenchmarkTools.params(t).memory_tolerance)
    timestr = BenchmarkTools.time(t) == 0 ? "-" : string(BenchmarkTools.prettytime(BenchmarkTools.time(t)), " (", t_tol, ")")
    memstr = BenchmarkTools.memory(t) == 0 ? "-" : string(BenchmarkTools.prettymemory(BenchmarkTools.memory(t)), " (", m_tol, ")")
    gcstr = BenchmarkTools.gctime(t) == 0 ? "-" : BenchmarkTools.prettytime(BenchmarkTools.gctime(t))
    allocstr = BenchmarkTools.allocs(t) == 0 ? "-" : string(BenchmarkTools.allocs(t))
    return "| `$(idrepr(ids))` | $(timestr) | $(gcstr) | $(memstr) | $(allocstr) |"
end

resultmark(sym::Symbol) = sym == :regression ? REGRESS_MARK : (sym == :improvement ? IMPROVE_MARK : "")