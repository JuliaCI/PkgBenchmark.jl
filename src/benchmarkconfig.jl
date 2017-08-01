"""
    BenchmarkConfig

A `BenchmarkConfig` contains the configuration for the benchmarks to be executed
by [`benchmarkpkg`](@ref).

This includes the following:

* The commit of the package the benchmarks are run on.
* What julia command should be run, i.e. the path to the Julia executable and
  the command flags used (e.g. optimization level with `-O`).
* Custom environment variables (e.g. `JULIA_NUM_THREADS`).
"""
immutable BenchmarkConfig
    id::Union{String,Void}
    juliacmd::Cmd
    env::Dict{String,Any}
end

function _hash(pkgname::String, pkgcommit::String, juliacommit, config::BenchmarkConfig)
    return hash(pkgname,
                hash(juliacommit,
                    hash(length(config.juliacmd) > 1 ? config.juliacmd[2:end] : 0,
                        hash(pkgcommit,
                            hash(config.env)))))
end

"""
    BenchmarkConfig(;id::Union{String, Void} = nothing,
                     juliacmd::Cmd = `$(joinpath(JULIA_HOME, Base.julia_exename()))`,
                     env::Dict{String, Any} = Dict{String, Any}())

Creates a `BenchmarkConfig` from the following keyword arguments:
* `id` - A git identifier like a commit, branch, tag, "HEAD", "HEAD~1" etc.
         If `id == nothing` then benchmark will be done on the current state
         of the repo (even if it is dirty).
* `juliacmd` - Used to exectue the benchmarks, defaults to the julia executable
               that the Pkgbenchmark-functions are called from. Can also include command flags.
* `env` - Contains custom environment variables that will be active when the
          benchmarks are run.

# Examples
```julia
BenchmarkConfig(id = "performance_improvements",
                juliacmd = `julia -O3`,
                env = Dict("JULIA_NUM_THREADS" => 4))
```
"""
function BenchmarkConfig(;id::Union{String,Void} = nothing,

                 juliacmd::Cmd = `$(joinpath(JULIA_HOME, Base.julia_exename()))`,
                 env::Dict = Dict{String,Any}())
    BenchmarkConfig(id, juliacmd, env)
end

BenchmarkConfig(cfg::BenchmarkConfig) = cfg
BenchmarkConfig(str::String) = BenchmarkConfig(id = str)
BenchmarkConfig(::Void) = BenchmarkConfig()

const _INDENT = "    "

function Base.show(io::IO, bcfg::BenchmarkConfig)
    println(io, "BenchmarkConfig:")
    println(io, _INDENT, "id: ", bcfg.id)
    println(io, _INDENT, "juliacmd: ", bcfg.juliacmd)
    print(io, _INDENT, "env: ")
    if !isempty(bcfg.env)
        first = true
        for (k, v) in bcfg.env
            if !first
                println(io)
                print(io, _INDENT, " "^strwidth("env: "))
            end
            first = false
            print(io, k, " => ", v)
        end
    end
end
