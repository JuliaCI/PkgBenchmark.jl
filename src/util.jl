function _withtemp(f, file)
    try f(file)
    catch err
        rethrow()
    finally
        try rm(file; force = true)
        catch
        end
    end
end


# Runs a function at a commit on a repo and afterwards goes back
# to the original commit / branch.
function _withcommit(f, repo, commit)
    original_commit = _shastring(repo, "HEAD")
    LibGit2.transact(repo) do r
        branch = try LibGit2.branch(r) catch err; nothing end
        try
            LibGit2.checkout!(r, _shastring(r, commit))
            f()
        catch err
            rethrow(err)
        finally
            if branch !== nothing
                LibGit2.branch!(r, branch)
            else
                LibGit2.checkout!(r, original_commit)
            end
        end
    end
end

_shastring(r::LibGit2.GitRepo, targetname) = string(LibGit2.revparseid(r, targetname))
_shastring(dir::AbstractString, targetname) = LibGit2.with(r -> _shastring(r, targetname), LibGit2.GitRepo(dir))

_benchinfo(str) = printstyled(stdout, "PkgBenchmark: ", str, "\n"; color = Base.info_color())
_benchwarn(str) = printstyled(stdout, "PkgBenchmark: ", str, "\n"; color = Base.info_color())

############
# Markdown #
############

_idrepr(id) = (str = repr(id); str[coalesce(findfirst(isequal('['), str), 0):end])
_intpercent(p) = string(ceil(Int, p * 100), "%")
_resultrow(ids, t::BenchmarkTools.Trial, col_widths) =
    _resultrow(ids, minimum(t), col_widths)

_update_col_widths!(col_widths, ids, t::BenchmarkTools.Trial) =
    _update_col_widths!(col_widths, ids, minimum(t))


function _resultrow(ids, t::BenchmarkTools.TrialEstimate, col_widths)
    t_tol = _intpercent(BenchmarkTools.params(t).time_tolerance)
    m_tol = _intpercent(BenchmarkTools.params(t).memory_tolerance)
    timestr = BenchmarkTools.time(t) == 0 ? "" : string(BenchmarkTools.prettytime(BenchmarkTools.time(t)), " (", t_tol, ")")
    memstr = BenchmarkTools.memory(t) == 0 ? "" : string(BenchmarkTools.prettymemory(BenchmarkTools.memory(t)), " (", m_tol, ")")
    gcstr = BenchmarkTools.gctime(t) == 0 ? "" : BenchmarkTools.prettytime(BenchmarkTools.gctime(t))
    allocstr = BenchmarkTools.allocs(t) == 0 ? "" : string(BenchmarkTools.allocs(t))
    return "| $(rpad("`"*_idrepr(ids)*"`", col_widths[1])) | $(lpad(timestr, col_widths[2])) | $(lpad(gcstr, col_widths[3])) | $(lpad(memstr, col_widths[4])) | $(lpad(allocstr, col_widths[5])) |"
end


function _update_col_widths!(col_widths, ids, t::BenchmarkTools.TrialEstimate)
    t_tol = _intpercent(BenchmarkTools.params(t).time_tolerance)
    m_tol = _intpercent(BenchmarkTools.params(t).memory_tolerance)
    timestr = BenchmarkTools.time(t) == 0 ? "" : string(BenchmarkTools.prettytime(BenchmarkTools.time(t)), " (", t_tol, ")")
    memstr = BenchmarkTools.memory(t) == 0 ? "" : string(BenchmarkTools.prettymemory(BenchmarkTools.memory(t)), " (", m_tol, ")")
    gcstr = BenchmarkTools.gctime(t) == 0 ? "" : BenchmarkTools.prettytime(BenchmarkTools.gctime(t))
    allocstr = BenchmarkTools.allocs(t) == 0 ? "" : string(BenchmarkTools.allocs(t))
    idrepr = "`"*_idrepr(ids)*"`"
    for (i, s) in enumerate((idrepr, timestr, gcstr, memstr, allocstr))
        w = length(s)
        if (w > col_widths[i]) col_widths[i] = w end
    end
end


function _resultrow(ids, t::BenchmarkTools.TrialJudgement, col_widths)
    t_tol = _intpercent(BenchmarkTools.params(t).time_tolerance)
    m_tol = _intpercent(BenchmarkTools.params(t).memory_tolerance)
    t_ratio = @sprintf("%.2f", BenchmarkTools.time(BenchmarkTools.ratio(t)))
    m_ratio =  @sprintf("%.2f", BenchmarkTools.memory(BenchmarkTools.ratio(t)))
    t_mark = _resultmark(BenchmarkTools.time(t))
    m_mark = _resultmark(BenchmarkTools.memory(t))
    timestr = "$(t_ratio) ($(t_tol)) $(t_mark)"
    memstr = "$(m_ratio) ($(m_tol)) $(m_mark)"
    return "| $(rpad("`"*_idrepr(ids)*"`", col_widths[1])) | $(lpad(timestr, col_widths[2])) | $(lpad(memstr, col_widths[3])) |"
end


function _update_col_widths!(col_widths, ids, t::BenchmarkTools.TrialJudgement)
    t_tol = _intpercent(BenchmarkTools.params(t).time_tolerance)
    m_tol = _intpercent(BenchmarkTools.params(t).memory_tolerance)
    t_ratio = @sprintf("%.2f", BenchmarkTools.time(BenchmarkTools.ratio(t)))
    m_ratio =  @sprintf("%.2f", BenchmarkTools.memory(BenchmarkTools.ratio(t)))
    t_mark = _resultmark(BenchmarkTools.time(t))
    m_mark = _resultmark(BenchmarkTools.memory(t))
    timestr = "$(t_ratio) ($(t_tol)) $(t_mark)"
    memstr = "$(m_ratio) ($(m_tol)) $(m_mark)"
    idrepr = "`"*_idrepr(ids)*"`"
    for (i, s) in enumerate((idrepr, timestr, memstr))
        w = length(s)
        if (w > col_widths[i]) col_widths[i] = w end
    end
end

_resultmark(sym::Symbol) = sym == :regression ? _REGRESS_MARK : (sym == :improvement ? _IMPROVE_MARK : "")

const _REGRESS_MARK = ":x:"
const _IMPROVE_MARK = ":white_check_mark:"
