# Run a function after loading a REQUIREs file.
# Clean up afterwards
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


function withtemp(f, file)
    try f(file)
    catch err
        rethrow()
    finally rm(file; force = true) end
end


# Runs a function at a commit on a repo and afterwards goes back
# to the original commit / branch.
function withcommit(f, repo, commit)
    LibGit2.transact(repo) do r
        branch = try LibGit2.branch(r) catch err; nothing end
        prev = shastring(r, "HEAD")
        try
            LibGit2.checkout!(r, shastring(r,commit))
            f()
        catch err
            rethrow(err)
        finally
            if branch !== nothing
                LibGit2.branch!(r, branch)
            end
        end
    end
end

shastring(r::LibGit2.GitRepo, refname) = string(LibGit2.revparseid(r, refname))
shastring(dir::AbstractString, refname) = LibGit2.with(r->shastring(r, refname), LibGit2.GitRepo(dir))
