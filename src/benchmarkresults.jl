"""
Stores the results from running the benchmarks on a package.

The following (unexported) methods are defined on a `BenchmarkResults` (written below as `results`):

* `name(results)::String` - The commit of the package benchmarked
* `commit(results)::String` - The commit of the package benchmarked. If the package repository was dirty, the string `"dirty"` is returned.
* `juliacommit(results)::String` - The commit of the Julia executable that ran the benchmarks
* `benchmarkgroup(results)::BenchmarkGroup` - a [`BenchmarkGroup`](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#the-benchmarkgroup-type)
   contaning the results of the benchmark.
* `date(results)::DateTime` - Tthe time when the benchmarks were executed
* `benchmarkconfig(results)::BenchmarkConfig` - The [`BenchmarkConfig`](@ref) used for the benchmarks.

`BenchmarkResults` can be exported to markdown using the function [`export_markdown`](@ref), and to CSV using the function `writecsv`.
"""
struct BenchmarkResults
    name::String
    commit::String
    benchmarkgroup::BenchmarkGroup
    date::DateTime
    julia_commit::String
    vinfo::String
    benchmarkconfig::BenchmarkConfig
end

name(results::BenchmarkResults) = results.name
commit(results::BenchmarkResults) = results.commit
juliacommit(results::BenchmarkResults) = results.julia_commit
benchmarkgroup(results::BenchmarkResults) = results.benchmarkgroup
date(results::BenchmarkResults) = results.date
benchmarkconfig(results::BenchmarkResults) = results.benchmarkconfig
Base.versioninfo(results::BenchmarkResults) = results.vinfo


function Base.show(io::IO, results::BenchmarkResults)
    print(io, "Benchmarkresults:\n")
    println(io, "    Package: ", results.name)
    println(io, "    Date: ", Base.Dates.format(results.date, "d u Y - HH:MM"))
    println(io, "    Package commit: ", results.commit[1:min(length(results.commit), 6)])
    println(io, "    Julia commit: ", results.julia_commit[1:6])
    iob = IOBuffer()
    ioc = IOContext(iob)
    show(ioc, MIME("text/plain"), results.benchmarkgroup)
    println(io,   "    BenchmarkGroup:")
    print(join("        " .* split(String(take!(iob)), "\n"), "\n"))
end


function writecsv(filename::AbstractString, A::BenchmarkResults; opts...)
    open(filename, "w") do f writecsv(f, A; opts...) end
end


function writecsv(f::IO, A::BenchmarkResults; header=true, quotes=true)
    n_ids = 0
    entries = BenchmarkTools.leaves(benchmarkgroup(A))
    for (ids, t) in entries
        if length(ids) > n_ids
            n_ids = length(ids)
        end
    end
    if header
        col_headers = vcat(
            ["ID$d" for d in 1:n_ids],
            ["time", "time tol", "GC time", "memory", "mem tol", "allocs"])
        writecsv(f, reshape(col_headers, (1,:)))
    end
    for (ids, t) in entries
        t_val = BenchmarkTools.time(t)
        t_tol = BenchmarkTools.params(t).time_tolerance
        gctime = BenchmarkTools.gctime(t)
        mem = BenchmarkTools.memory(t)
        m_tol = BenchmarkTools.params(t).memory_tolerance
        allocs = BenchmarkTools.allocs(t)
        row = vcat(ids, repeat([""], inner=[n_ids-length(ids)]),
                   [t_val, t_tol, gctime, mem, m_tol, allocs])
        writecsv(f, reshape(row, (1,:)); quotes=quotes)
    end
end


"""
    writeresults(file::String, results::BenchmarkResults)

Writes the [`BenchmarkResults`](@ref) to `file`.
"""
function writeresults(file::String, results::BenchmarkResults)
    open(file, "w") do io
        JSON.print(io,
            Dict(
                "name" => results.name,
                "commit" => results.commit,
                "benchmarkgroup" => sprint(BenchmarkTools.save, results.benchmarkgroup),
                "date" => results.date,
                "julia_commit" => results.julia_commit,
                "vinfo" => results.vinfo,
                "benchmarkconfig" => results.benchmarkconfig
            )
        )
    end
end

"""
    readresults(file::String)

Reads the [`BenchmarkResults`](@ref) stored in `file` (given as a path).
"""
function readresults(file::String)
    d = JSON.parsefile(file)
    BenchmarkResults(
        d["name"],
        d["commit"],
        BenchmarkTools.load(IOBuffer(d["benchmarkgroup"]))[1],
        DateTime(d["date"]),
        d["julia_commit"],
        d["vinfo"],
        BenchmarkConfig(d["benchmarkconfig"]),
    )
end

"""
    export_markdown(file::String, results::Union{BenchmarkResults, BenchmarkJudgement})
    export_markdown(io::IO,       results::Union{BenchmarkResults, BenchmarkJudgement})

Writes the `results` to `file` or `io` in markdown format.

See also: [`BenchmarkResults`](@ref), [`BenchmarkJudgement`](@ref)
"""
function export_markdown(file::String, results::BenchmarkResults)
    open(file, "w") do f
        export_markdown(f, results)
    end
end

function export_markdown(io::IO, results::BenchmarkResults)
    env_str = if isempty(benchmarkconfig(results).env)
        "None"
    else
        join(String[string("`", k, " => ", v, "`") for (k, v) in benchmarkconfig(results).env], " ")
    end

    jlcmd = benchmarkconfig(results).juliacmd
    flags = length(jlcmd) <= 1 ? [] : jlcmd[2:end]
    julia_command_flags = if isempty(flags)
        "None"
    else
        """`$(join(flags, ","))`"""
    end

    println(io, """
                # Benchmark Report for *$(name(results))*

                ## Job Properties
                * Time of benchmark: $(Base.Dates.format(date(results), "d u Y - H:M"))
                * Package commit: $(commit(results)[1:min(6, length(commit(results)))])
                * Julia commit: $(juliacommit(results)[1:min(6, length(juliacommit(results)))])
                * Julia command flags: $julia_command_flags
                * Environment variables: $env_str
                """)

      println(io, """
                ## Results
                Below is a table of this job's results, obtained by running the benchmarks.
                The values listed in the `ID` column have the structure `[parent_group, child_group, ..., key]`, and can be used to
                index into the BaseBenchmarks suite to retrieve the corresponding benchmarks.
                The percentages accompanying time and memory values in the below table are noise tolerances. The "true"
                time/memory value for a given benchmark is expected to fall within this percentage of the reported value.
                An empty cell means that the value was zero.
                """)

    entries = BenchmarkTools.leaves(benchmarkgroup(results))
    entries = entries[sortperm(map(x -> string(first(x)), entries))]

    cw = [2, 4, 7, 6, 11]
    for (ids, t) in entries
        _update_col_widths!(cw, ids, t)
    end

    print(io, """
                | ID$(" "^(cw[1]-2)) | time$(" "^(cw[2]-4)) | GC time$(" "^(cw[3]-7)) | memory$(" "^(cw[4]-6)) | allocations$(" "^(cw[5]-11)) |
                |---$("-"^(cw[1]-2))-|-----$("-"^(cw[2]-4)):|--------$("-"^(cw[3]-7)):|-------$("-"^(cw[4]-6)):|------------$("-"^(cw[5]-11)):|
                """)


    for (ids, t) in entries
        println(io, _resultrow(ids, t, cw))
    end
    println(io)
    println(io, """
                ## Benchmark Group List
                Here's a list of all the benchmark groups executed by this job:
                """)

    for id in unique(map(pair -> pair[1][1:end-1], entries))
        println(io, "- `", _idrepr(id), "`")
    end

    println(io)
    println(io, "## Julia versioninfo")
    print(io, "```\n", versioninfo(results), "```")

    return nothing
end
