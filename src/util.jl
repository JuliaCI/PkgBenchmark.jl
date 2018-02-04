# Run a function after loading a REQUIREs file.
# Clean up afterwards
function _with_reqs(f, reqs::AbstractString, pre = () -> nothing)
    if isfile(reqs)
        _with_reqs(f, Pkg.Reqs.parse(reqs), pre)
    else
        f()
    end
end

function _with_reqs(f, reqs::Dict, pre = () -> nothing)
    pre()
    cd(Pkg.dir()) do
        Pkg.Entry.resolve(merge(Pkg.Reqs.parse("REQUIRE"), reqs))
    end
    try f() catch ex rethrow() finally cd(Pkg.Entry.resolve, Pkg.dir()) end
end


function _withtemp(f, file)
    try f(file)
    catch err
        rethrow()
    finally
        try rm(file; force = true) end
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

_benchinfo(str) = print_with_color(Base.info_color(), STDOUT, "PkgBenchmark: ", str, "\n")
_benchwarn(str) = print_with_color(Base.info_color(), STDOUT, "PkgBenchmark: ", str, "\n")

############
# Markdown #
############

_idrepr(id) = (str = repr(id); str[searchindex(str, '['):end])
_intpercent(p) = string(ceil(Int, p * 100), "%")
_resultrow(ids, t::BenchmarkTools.Trial) = _resultrow(ids, minimum(t))

function _resultrow(ids, t::BenchmarkTools.TrialEstimate)
    t_tol = _intpercent(BenchmarkTools.params(t).time_tolerance)
    m_tol = _intpercent(BenchmarkTools.params(t).memory_tolerance)
    timestr = BenchmarkTools.time(t) == 0 ? "" : string(BenchmarkTools.prettytime(BenchmarkTools.time(t)), " (", t_tol, ")")
    memstr = BenchmarkTools.memory(t) == 0 ? "" : string(BenchmarkTools.prettymemory(BenchmarkTools.memory(t)), " (", m_tol, ")")
    gcstr = BenchmarkTools.gctime(t) == 0 ? "" : BenchmarkTools.prettytime(BenchmarkTools.gctime(t))
    allocstr = BenchmarkTools.allocs(t) == 0 ? "" : string(BenchmarkTools.allocs(t))
    return "| `$(_idrepr(ids))` | $(timestr) | $(gcstr) | $(memstr) | $(allocstr) |"
end


function _resultrow(ids, t::BenchmarkTools.TrialJudgement)
    t_tol = _intpercent(BenchmarkTools.params(t).time_tolerance)
    m_tol = _intpercent(BenchmarkTools.params(t).memory_tolerance)
    t_ratio = @sprintf("%.2f", BenchmarkTools.time(BenchmarkTools.ratio(t)))
    m_ratio =  @sprintf("%.2f", BenchmarkTools.memory(BenchmarkTools.ratio(t)))
    t_mark = _resultmark(BenchmarkTools.time(t))
    m_mark = _resultmark(BenchmarkTools.memory(t))
    timestr = "$(t_ratio) ($(t_tol)) $(t_mark)"
    memstr = "$(m_ratio) ($(m_tol)) $(m_mark)"
    return "| `$(_idrepr(ids))` | $(timestr) | $(memstr) |"
end

_resultmark(sym::Symbol) = sym == :regression ? _REGRESS_MARK : (sym == :improvement ? _IMPROVE_MARK : "")

const _REGRESS_MARK = ":x:"
const _IMPROVE_MARK = ":white_check_mark:"