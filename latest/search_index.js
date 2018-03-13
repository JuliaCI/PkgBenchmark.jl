var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#PkgBenchmarks-1",
    "page": "Home",
    "title": "PkgBenchmarks",
    "category": "section",
    "text": "PkgBenchmark provides an interface for Julia package developers to track performance changes of their packages.The package contains the following featuresRunning the benchmark suite at a specified commit, branch or tag. The path to the julia executable, the command line flags, and the environment variables can be customized.\nComparing performance of a package between different package commits, branches or tags.\nExporting results to markdown for benchmarks and comparisons, similar to how Nanosoldier reports results for the benchmarks in Base Julia."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "PkgBenchmark is registered in METADATA so installation is done by running Pkg.add(\"PkgBenchmark\")."
},

{
    "location": "define_benchmarks.html#",
    "page": "Defining a benchmark suite",
    "title": "Defining a benchmark suite",
    "category": "page",
    "text": ""
},

{
    "location": "define_benchmarks.html#Defining-a-benchmark-suite-1",
    "page": "Defining a benchmark suite",
    "title": "Defining a benchmark suite",
    "category": "section",
    "text": "Benchmarks are to be written in <PKGROOT>/benchmark/benchmarks.jl and are defined using the standard dictionary based interface from BenchmarkTools, as documented here. The naming convention that must be used is to name the benchmark suite variable SUITE. An example file using the dictionary based interface can be found here. Note that there is no need to have PkgBenchmark loaded to define the benchmark suite.note: Note\nRunning this script directly does not actually run the benchmarks, this is the job of PkgBenchmark, see the next section."
},

{
    "location": "define_benchmarks.html#Custom-requirements-for-benchmarks-1",
    "page": "Defining a benchmark suite",
    "title": "Custom requirements for benchmarks",
    "category": "section",
    "text": "<PKGROOT>/benchmark/REQUIRE can contain dependencies needed to run the benchmark suite, similarly how <PKGROOT>/test/REQUIRE can contain dependencies for the tests."
},

{
    "location": "run_benchmarks.html#",
    "page": "Running a benchmark suite",
    "title": "Running a benchmark suite",
    "category": "page",
    "text": "DocTestSetup  = quote\n    using PkgBenchmark\nend"
},

{
    "location": "run_benchmarks.html#PkgBenchmark.benchmarkpkg",
    "page": "Running a benchmark suite",
    "title": "PkgBenchmark.benchmarkpkg",
    "category": "function",
    "text": "benchmarkpkg(pkg, [target]::Union{String, BenchmarkConfig}; kwargs...)\n\nRun a benchmark on the package pkg using the BenchmarkConfig or git identifier target. Examples of git identifiers are commit shas, branch names, or e.g. \"HEAD~1\". Return a BenchmarkResults.\n\nThe argument pkg can be a name of a package or a path to a directory to a package.\n\nKeyword arguments:\n\nscript - The script with the benchmarks, if not given, defaults to benchmark/benchmarks.jl in the package folder.\nresultfile - If set, saves the output to resultfile\nretune - Force a re-tune, saving the new tuning to the tune file.\n\nThe result can be used by functions such as judge. If you choose to, you can save the results manually using writeresults where results is the return value of this function. It can be read back with readresults.\n\nIf a REQUIRE file exists in the same folder as script, load package requirements from that file before benchmarking.\n\nExample invocations:\n\nusing PkgBenchmark\n\nbenchmarkpkg(\"MyPkg\") # run the benchmarks at the current state of the repository\nbenchmarkpkg(\"MyPkg\", \"my-feature\") # run the benchmarks for a particular branch/commit/tag\nbenchmarkpkg(\"MyPkg\", \"my-feature\"; script=\"/home/me/mycustombenchmark.jl\")\nbenchmarkpkg(\"MyPkg\", BenchmarkConfig(id = \"my-feature\",\n                                      env = Dict(\"JULIA_NUM_THREADS\" => 4),\n                                      juliacmd = `julia -O3`))\n\n\n\n"
},

{
    "location": "run_benchmarks.html#PkgBenchmark.BenchmarkResults",
    "page": "Running a benchmark suite",
    "title": "PkgBenchmark.BenchmarkResults",
    "category": "type",
    "text": "Stores the results from running the benchmarks on a package.\n\nThe following (unexported) methods are defined on a BenchmarkResults (written below as results):\n\nname(results)::String - The commit of the package benchmarked\ncommit(results)::String - The commit of the package benchmarked. If the package repository was dirty, the string \"dirty\" is returned.\njuliacommit(results)::String - The commit of the Julia executable that ran the benchmarks\nbenchmarkgroup(results)::BenchmarkGroup - a BenchmarkGroup  contaning the results of the benchmark.\ndate(results)::DateTime - Tthe time when the benchmarks were executed\nbenchmarkconfig(results)::BenchmarkConfig - The BenchmarkConfig used for the benchmarks.\n\nBenchmarkResults can be exported to markdown using the function export_markdown.\n\n\n\n"
},

{
    "location": "run_benchmarks.html#Running-a-benchmark-suite-1",
    "page": "Running a benchmark suite",
    "title": "Running a benchmark suite",
    "category": "section",
    "text": "Use benchmarkpkg to run benchmarks defined in a suite as defined in the previous section.benchmarkpkgThe results of a benchmark is returned as a BenchmarkResultPkgBenchmark.BenchmarkResults"
},

{
    "location": "run_benchmarks.html#More-advanced-customization-1",
    "page": "Running a benchmark suite",
    "title": "More advanced customization",
    "category": "section",
    "text": "Instead of passing a commit, branch etc. as a String to benchmarkpkg, a BenchmarkConfig can be passed. This object contains the package commit, julia command, and what environment variables will be used when benchmarking. The default values can be seen by using the default constructorjulia> BenchmarkConfig()\nBenchmarkConfig:\n    id: nothing\n    juliacmd: `/home/user/julia/julia`\n    env:The id is a commit, branch etc as described in the previous section. An id with value nothing means that the current state of the package will be benchmarked. The default value of juliacmd is joinpath(JULIA_HOME, Base.julia_exename() which is the command to run the julia executable without any command line arguments.To instead benchmark the branch PR, using the julia command julia -O3 with the environment variable JULIA_NUM_THREADS set to 4, the config would be created asjulia> config = BenchmarkConfig(id = \"PR\",\n                                juliacmd = `julia -O3`,\n                                env = Dict(\"JULIA_NUM_THREADS\" => 4))\nBenchmarkConfig:\n    id: PR\n    juliacmd: `julia -O3`\n    env: JULIA_NUM_THREADS => 4To benchmark the package with the config, call benchmarkpkg as e.g.benchmark(\"Tensors\", config)info: Info\nThe id keyword to the BenchmarkConfig does not have to be a branch, it can be most things that git can understand, for example a commit id or a tag."
},

{
    "location": "comparing_commits.html#",
    "page": "Comparing commits",
    "title": "Comparing commits",
    "category": "page",
    "text": ""
},

{
    "location": "comparing_commits.html#BenchmarkTools.judge",
    "page": "Comparing commits",
    "title": "BenchmarkTools.judge",
    "category": "function",
    "text": "judge(pkg::String,\n      [target]::Union{String, BenchmarkConfig},\n      baseline::Union{String, BenchmarkConfig};\n      kwargs...)\n\nArguments:\n\npkg - The package to benchmark.\ntarget - What do judge, given as a git id or a BenchmarkConfig. If skipped, use the current state of the package repo.\nbaseline - The commit / BenchmarkConfig to compare target against.\n\nKeyword arguments:\n\nf - Estimator function to use in the judging.\njudgekwargs::Dict{Symbol, Any} - keyword arguments to pass to the judge function in BenchmarkTools\n\nThe remaining keyword arguments are passed to benchmarkpkg\n\nReturn value:\n\nReturns a BenchmarkJudgement\n\n\n\njudge(target::BenchmarkResults, baseline::BenchmarkResults, f;\n      judgekwargs = Dict())\n\nJudges the two BenchmarkResults in target and baseline using the function f.\n\nReturn value\n\nReturns a BenchmarkJudgement\n\n\n\n"
},

{
    "location": "comparing_commits.html#Comparing-commits-1",
    "page": "Comparing commits",
    "title": "Comparing commits",
    "category": "section",
    "text": "You can use judge to compare benchmark results of two versions of the package.judge"
},

{
    "location": "export_markdown.html#",
    "page": "Export to markdown",
    "title": "Export to markdown",
    "category": "page",
    "text": ""
},

{
    "location": "export_markdown.html#PkgBenchmark.export_markdown",
    "page": "Export to markdown",
    "title": "PkgBenchmark.export_markdown",
    "category": "function",
    "text": "export_markdown(file::String, results::Union{BenchmarkResults, BenchmarkJudgement})\nexport_markdown(io::IO,       results::Union{BenchmarkResults, BenchmarkJudgement})\n\nWrites the results to file or io in markdown format.\n\nSee also: BenchmarkResults, BenchmarkJudgement\n\n\n\n"
},

{
    "location": "export_markdown.html#Export-to-markdown-1",
    "page": "Export to markdown",
    "title": "Export to markdown",
    "category": "section",
    "text": "It is possible to export results from PkgBenchmark.BenchmarkResults and  PkgBenchmark.BenchmarkJudgement  using the function export_markdownexport_markdown"
},

{
    "location": "export_markdown.html#Using-Github.jl-to-upload-the-markdown-to-a-Gist-1",
    "page": "Export to markdown",
    "title": "Using Github.jl to upload the markdown to a Gist",
    "category": "section",
    "text": "Assuming that we have gotten a BenchmarkResults or BenchmarkJudgement from a benchmark, we can then use GitHub.jl to programatically upload the exported markdown to a gist:julia> using GitHub, JSON, PkgBenchmark\n\njulia> results = benchmarkpkg(\"PkgBenchmark\");\n\njulia> gist_json = JSON.parse(\n            \"\"\"\n            {\n            \"description\": \"A benchmark for PkgBenchmark\",\n            \"public\": false,\n            \"files\": {\n                \"benchmark.md\": {\n                \"content\": \"$(escape_string(sprint(export_markdown, results)))\"\n                }\n            }\n            }\n            \"\"\"\n        )\n\njulia> posted_gist = create_gist(params = gist_json);\n\njulia> url = get(posted_gist.html_url)\nURI(https://gist.github.com/317378b4fcf2fb4c5585b104c3b177a8)note: Note\nConsider using an extension to your browser to make the gist webpage use full width in order for the tables in the gist to render better, see e.g here."
},

{
    "location": "ref.html#PkgBenchmark.BenchmarkConfig",
    "page": "Reference",
    "title": "PkgBenchmark.BenchmarkConfig",
    "category": "type",
    "text": "BenchmarkConfig\n\nA BenchmarkConfig contains the configuration for the benchmarks to be executed by benchmarkpkg.\n\nThis includes the following:\n\nThe commit of the package the benchmarks are run on.\nWhat julia command should be run, i.e. the path to the Julia executable and the command flags used (e.g. optimization level with -O).\nCustom environment variables (e.g. JULIA_NUM_THREADS).\n\n\n\n"
},

{
    "location": "ref.html#PkgBenchmark.BenchmarkConfig-Tuple{}",
    "page": "Reference",
    "title": "PkgBenchmark.BenchmarkConfig",
    "category": "method",
    "text": "BenchmarkConfig(;id::Union{String, Void} = nothing,\n                 juliacmd::Cmd = `joinpath(JULIA_HOME, Base.julia_exename())`,\n                 env::Dict{String, Any} = Dict{String, Any}())\n\nCreates a BenchmarkConfig from the following keyword arguments:\n\nid - A git identifier like a commit, branch, tag, \"HEAD\", \"HEAD~1\" etc.        If id == nothing then benchmark will be done on the current state        of the repo (even if it is dirty).\njuliacmd - Used to exectue the benchmarks, defaults to the julia executable              that the Pkgbenchmark-functions are called from. Can also include command flags.\nenv - Contains custom environment variables that will be active when the         benchmarks are run.\n\nExamples\n\njulia> using Pkgbenchmark\n\njulia> BenchmarkConfig(id = \"performance_improvements\",\n                       juliacmd = `julia -O3`,\n                       env = Dict(\"JULIA_NUM_THREADS\" => 4))\nBenchmarkConfig:\n    id: performance_improvements\n    juliacmd: `julia -O3`\n    env: JULIA_NUM_THREADS => 4\n\n\n\n"
},

{
    "location": "ref.html#PkgBenchmark.BenchmarkJudgement",
    "page": "Reference",
    "title": "PkgBenchmark.BenchmarkJudgement",
    "category": "type",
    "text": "Stores the results from running a judgement, see judge.\n\nThe following (unexported) methods are defined on a BenchmarkJudgement (written below as judgement):\n\ntarget_result(judgement)::BenchmarkResults - the BenchmarkResults of the target.\nbaseline_result(judgement)::BenchmarkResults -  the BenchmarkResults of the baseline.\nbenchmarkgroup(judgement)::BenchmarkGroup - a BenchmarkGroup  contaning the estimated results\n\nA BenchmarkJudgement can be exported to markdown using the function export_markdown.\n\nSee also BenchmarkResults\n\n\n\n"
},

{
    "location": "ref.html#BenchmarkTools.judge",
    "page": "Reference",
    "title": "BenchmarkTools.judge",
    "category": "function",
    "text": "judge(target::BenchmarkResults, baseline::BenchmarkResults, f;\n      judgekwargs = Dict())\n\nJudges the two BenchmarkResults in target and baseline using the function f.\n\nReturn value\n\nReturns a BenchmarkJudgement\n\n\n\n"
},

{
    "location": "ref.html#BenchmarkTools.judge-Tuple{String,Union{PkgBenchmark.BenchmarkConfig, String},Union{PkgBenchmark.BenchmarkConfig, String}}",
    "page": "Reference",
    "title": "BenchmarkTools.judge",
    "category": "method",
    "text": "judge(pkg::String,\n      [target]::Union{String, BenchmarkConfig},\n      baseline::Union{String, BenchmarkConfig};\n      kwargs...)\n\nArguments:\n\npkg - The package to benchmark.\ntarget - What do judge, given as a git id or a BenchmarkConfig. If skipped, use the current state of the package repo.\nbaseline - The commit / BenchmarkConfig to compare target against.\n\nKeyword arguments:\n\nf - Estimator function to use in the judging.\njudgekwargs::Dict{Symbol, Any} - keyword arguments to pass to the judge function in BenchmarkTools\n\nThe remaining keyword arguments are passed to benchmarkpkg\n\nReturn value:\n\nReturns a BenchmarkJudgement\n\n\n\n"
},

{
    "location": "ref.html#PkgBenchmark.benchmarkpkg",
    "page": "Reference",
    "title": "PkgBenchmark.benchmarkpkg",
    "category": "function",
    "text": "benchmarkpkg(pkg, [target]::Union{String, BenchmarkConfig}; kwargs...)\n\nRun a benchmark on the package pkg using the BenchmarkConfig or git identifier target. Examples of git identifiers are commit shas, branch names, or e.g. \"HEAD~1\". Return a BenchmarkResults.\n\nThe argument pkg can be a name of a package or a path to a directory to a package.\n\nKeyword arguments:\n\nscript - The script with the benchmarks, if not given, defaults to benchmark/benchmarks.jl in the package folder.\nresultfile - If set, saves the output to resultfile\nretune - Force a re-tune, saving the new tuning to the tune file.\n\nThe result can be used by functions such as judge. If you choose to, you can save the results manually using writeresults where results is the return value of this function. It can be read back with readresults.\n\nIf a REQUIRE file exists in the same folder as script, load package requirements from that file before benchmarking.\n\nExample invocations:\n\nusing PkgBenchmark\n\nbenchmarkpkg(\"MyPkg\") # run the benchmarks at the current state of the repository\nbenchmarkpkg(\"MyPkg\", \"my-feature\") # run the benchmarks for a particular branch/commit/tag\nbenchmarkpkg(\"MyPkg\", \"my-feature\"; script=\"/home/me/mycustombenchmark.jl\")\nbenchmarkpkg(\"MyPkg\", BenchmarkConfig(id = \"my-feature\",\n                                      env = Dict(\"JULIA_NUM_THREADS\" => 4),\n                                      juliacmd = `julia -O3`))\n\n\n\n"
},

{
    "location": "ref.html#PkgBenchmark.export_markdown-Tuple{String,PkgBenchmark.BenchmarkResults}",
    "page": "Reference",
    "title": "PkgBenchmark.export_markdown",
    "category": "method",
    "text": "export_markdown(file::String, results::Union{BenchmarkResults, BenchmarkJudgement})\nexport_markdown(io::IO,       results::Union{BenchmarkResults, BenchmarkJudgement})\n\nWrites the results to file or io in markdown format.\n\nSee also: BenchmarkResults, BenchmarkJudgement\n\n\n\n"
},

{
    "location": "ref.html#PkgBenchmark.readresults-Tuple{String}",
    "page": "Reference",
    "title": "PkgBenchmark.readresults",
    "category": "method",
    "text": "readresults(file::String)\n\nReads the BenchmarkResults stored in file (given as a path).\n\n\n\n"
},

{
    "location": "ref.html#PkgBenchmark.writeresults-Tuple{String,PkgBenchmark.BenchmarkResults}",
    "page": "Reference",
    "title": "PkgBenchmark.writeresults",
    "category": "method",
    "text": "writeresults(file::String, results::BenchmarkResults)\n\nWrites the BenchmarkResults to file.\n\n\n\n"
},

{
    "location": "ref.html#",
    "page": "Reference",
    "title": "Reference",
    "category": "page",
    "text": "Pages = [\"ref.md\"]\nModules = [PkgBenchmark]Modules = [PkgBenchmark]\nPrivate = false"
},

]}
