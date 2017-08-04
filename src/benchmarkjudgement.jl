"""
Stores the results from running a judgement, see [`judge`](@ref).

The following (unexported) methods are defined on a `BenchmarkJudgement` (written below as `judgement`):

* `target_result(judgement)::BenchmarkResults` - the [`BenchmarkResults`](@ref) of the `target`.
* `baseline_result(judgement)::BenchmarkResults` -  the [`BenchmarkResults`](@ref) of the `baseline`.
* `benchmarkgroup(judgement)::BenchmarkGroup` - a [`BenchmarkGroup`](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md#the-benchmarkgroup-type)
   contaning the estimated results

A `BenchmarkJudgement` can be exported to markdown using the function [`export_markdown`](@ref).

See also [`BenchmarkResults`](@ref)
"""
immutable BenchmarkJudgement
    target_results::BenchmarkResults
    baseline_results::BenchmarkResults
    benchmarkgroup::BenchmarkGroup
end


target_result(judgement::BenchmarkJudgement) = judgement.target_result
baseline_result(judgement::BenchmarkJudgement) = judgement.baseline_result
benchmarkgroup(judgement::BenchmarkJudgement) = judgement.benchmarkgroup

function Base.show(io::IO, judgement::BenchmarkJudgement)
    target, base = judgement.target_results, judgement.baseline_results
    print(io, "Benchmarkjudgement (target / baseline):\n")
    println(io, "    Package: ", target.name)
    println(io, "    Dates: ", Base.Dates.format(target.date,  "m u Y - H:M"), " / ",
                               Base.Dates.format(base.date, "m u Y - H:M"))
    println(io, "    Package commits: ", target.commit[1:min(length(target.commit), 6)], " / ",
                                        base.commit[1:min(length(base.commit), 6)])
    println(io, "    Julia commits: ", target.julia_commit[1:6], " / ",
                                       base.julia_commit[1:6])
end


"""
export_markdown(file::String, judgement::BenchmarkJudgement)
export_markdown(io::IO, judgement::BenchmarkJudgement)

Writes the `judgement` to `file` or `io` in markdown format.

See also: [`BenchmarkJudgement`](@ref)
"""
function export_markdown(io::IO, judgement::BenchmarkJudgement)
    target, baseline = judgement.target_results, judgement.baseline_results
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
                # Benchmark Report for *$(name(target))*
                
                ## Job Properties
                * Time of benchmarks:
                    - Target: $(Base.Dates.format(date(target), "d u Y - H:M"))
                    - Baseline: $(Base.Dates.format(date(baseline), "d u Y - H:M"))
                * Package commits: 
                    - Target: $(commit(target)[1:min(6, length(commit(target)))])
                    - Baseline: $(commit(baseline)[1:min(6, length(commit(baseline)))])
                * Julia commits:
                    - Target: $(juliacommit(target)[1:min(6, length(juliacommit(target)))])
                    - Baseline: $(juliacommit(baseline)[1:min(6, length(juliacommit(baseline)))])
                * Julia command flags: 
                    - Target: $(jlstr(target))
                    - Baseline: $(jlstr(baseline))
                * Environment variables: 
                    - Target: $(env_strs(target))
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

    println(io, "\n### Target")
    print(io, "```\n", versioninfo(target), "```")

    println(io, "\n\n### Baseline")
    print(io, "```\n", versioninfo(baseline), "```")


    return nothing
end
