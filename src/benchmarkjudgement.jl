"""
Stores the results from running a judgement, see [`judge`](@ref).

The following (unexported) methods are defined on a `BenchmarkJudgement` (written below as `judgement`):

* `ref_result(judgement)::BenchmarkResults` - the [`BenchmarkResults`](@ref) of the `ref`.
* `baseline_result(judgement)::BenchmarkResults` -  the [`BenchmarkResults`](@ref) of the `baseline`.
* `benchmarkgroup(judgement)::BenchmarkGroup` - a [`BenchmarkGroup`](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#the-benchmarkgroup-type)
   contaning the estimated results

A `BenchmarkJudgement` can be exported to markdown using the function [`export_markdown`](@ref).

See also [`BenchmarkResults`](@ref)
"""
immutable BenchmarkJudgement
    ref_results::BenchmarkResults
    baseline_results::BenchmarkResults
    benchmarkgroup::BenchmarkGroup
end


ref_result(judgement::BenchmarkJudgement) = judgement.ref_result
baseline_result(judgement::BenchmarkJudgement) = judgement.baseline_result
benchmarkgroup(judgement::BenchmarkJudgement) = judgement.benchmarkgroup

function Base.show(io::IO, judgment::BenchmarkJudgement)
    ref, base = judgment.ref_results, judgment.baseline_results
    print(io, "Benchmarkjudgment (ref / baseline):\n")
    println(io, "    Package: ", ref.name)
    println(io, "    Dates: ", Base.Dates.format(ref.date,  "m u Y - H:M"), " / ",
                               Base.Dates.format(base.date, "m u Y - H:M"))
    println(io, "    Package commits: ", ref.commit[1:min(length(ref.commit), 6)], " / ",
                                        base.commit[1:min(length(base.commit), 6)])
    println(io, "    Julia commits: ", ref.julia_commit[1:6], " / ",
                                       base.julia_commit[1:6])
end


"""
export_markdown(file::String, judgement::BenchmarkJudgment)
export_markdown(io::IO, judgement::BenchmarkJudgment)

Writes the `judgement` to `file` or `io` in markdown format.

See also: [`BenchmarkJudgment`](@ref)
"""
function export_markdown(io::IO, judgement::BenchmarkJudgement)
    ref, baseline = judgement.ref_results, judgement.baseline_results
    function env_strs(res)
        return if isempty(benchmarkconfig(res).env)
            "None"
        else
            join(String[string("`", k, " => ", v, "`") for (k, v) in benchmarkconfig(res).env], " ")
        end
    end

    function jlstr(res)
        jlcmd = benchmarkconfig(res).juliacmd
        flags = length(jlcmd) <= 1 ? [] : jlcmd[2:end]
        return if isempty(flags)
            "None"
        else
            """`$(join(flags, ","))`"""
        end
    end
    
    println(io, """
                # Benchmark Report for *$(name(ref))*
                
                ## Job Properties
                * Time of benchmarks:
                    - Ref: $(Base.Dates.format(date(ref), "m u Y - H:M"))
                    - Baseline: $(Base.Dates.format(date(baseline), "m u Y - H:M"))
                * Package commits: 
                    - Ref: $(commit(ref)[1:min(6, length(commit(ref)))])
                    - Baseline: $(commit(baseline)[1:min(6, length(commit(baseline)))])
                * Julia commits:
                    - Ref: $(juliacommit(ref)[1:min(6, length(juliacommit(ref)))])
                    - Baseline: $(juliacommit(baseline)[1:min(6, length(juliacommit(baseline)))])
                * Julia command flags: 
                    - Ref: $(jlstr(ref))
                    - Baseline: $(jlstr(baseline))
                * Environment variables: 
                    - Ref: $(env_strs(ref))
                    - Baseline: $(env_strs(baseline))
                """)

    print(io, """
                ## Results
                A ratio greater than `1.0` denotes a possible regression (marked with $(_REGRESS_MARK)), while a ratio less
                than `1.0` denotes a possible improvement (marked with $(_IMPROVE_MARK)). Only significant results - results
                that indicate possible regressions or improvements - are shown below (thus, an empty table means that all
                benchmark results remained invariant between builds).

                | ID | time ratio | memory ratio |
                |----|------------|--------------|
                """)

    entries = BenchmarkTools.leaves(benchmarkgroup(judgement))
    entries = entries[sortperm(map(x -> string(first(x)), entries))]

    for (ids, t) in entries
        if BenchmarkTools.isregression(t) || BenchmarkTools.isimprovement(t)
            println(io, _resultrow(ids, t))
        end
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

    println("\n### Ref")
    print(io, "```\n", versioninfo(ref), "```")

    println("\n\n### Baseline")
    print(io, "```\n", versioninfo(baseline), "```")


    return nothing
end
