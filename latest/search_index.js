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
    "text": "Convention and helper functions for package developers to track performance changes in Julia packages.The package contains the following features:A macro based interface, similar to the Base.Test interface, to define a suite of benchmarks.\nRunning the benchmark suite at a specified commit, branch or tag.\nComparing performance of a package between different package commits, branches or tags."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "PkgBenchmark is registered in METADATA so installation is done by running Pkg.add(\"PkgBenchmark\")."
},

{
    "location": "man/define_benchmarks.html#",
    "page": "Defining a benchmark suite",
    "title": "Defining a benchmark suite",
    "category": "page",
    "text": ""
},

{
    "location": "man/define_benchmarks.html#Defining-a-benchmark-suite-1",
    "page": "Defining a benchmark suite",
    "title": "Defining a benchmark suite",
    "category": "section",
    "text": ""
},

{
    "location": "man/define_benchmarks.html#Conventions-1",
    "page": "Defining a benchmark suite",
    "title": "Conventions",
    "category": "section",
    "text": "Benchmarks are to be written in <PKGROOT>/benchmark/benchmarks.jl and must use the @benchgroup and @bench macros. These are analogous to @testset and @test macros, with slightly different syntax.\n<PKGROOT>/benchmark/REQUIRE can contain dependencies needed to run the benchmark suite."
},

{
    "location": "man/define_benchmarks.html#Writing-benchmarks-1",
    "page": "Defining a benchmark suite",
    "title": "Writing benchmarks",
    "category": "section",
    "text": ""
},

{
    "location": "man/define_benchmarks.html#@benchgroup-1",
    "page": "Defining a benchmark suite",
    "title": "@benchgroup",
    "category": "section",
    "text": "@benchgroup defines a benchmark group. It can contain nested @benchgroup and @bench expressions.Syntax:@benchgroup <name> [<tags>] begin\n  <expr>\nend<name> is a string naming the benchmark group. <tags> is a vector of strings, tags for the benchmark group, and is optional. <expr> are expressions that can contain @benchgroup or @bench calls."
},

{
    "location": "man/define_benchmarks.html#@bench-1",
    "page": "Defining a benchmark suite",
    "title": "@bench",
    "category": "section",
    "text": "@bench creates a benchmark under the current @benchgroup.Syntax:@bench <name>... <expr><name> is a name/id for the benchmark, the last argument to @bench, <expr>, is the expression to be benchmarked, and has the same interpolation features as the @benchmarkable macro from BenchmarkTools."
},

{
    "location": "man/define_benchmarks.html#Example-1",
    "page": "Defining a benchmark suite",
    "title": "Example",
    "category": "section",
    "text": "An example benchmark/benchmarks.jl script would look like:using PkgBenchmark\n\n@benchgroup \"utf8\" [\"string\", \"unicode\"] begin\n    teststr = UTF8String(join(rand(MersenneTwister(1), 'a':'d', 10^4)))\n    @bench \"replace\" replace($teststr, \"a\", \"b\")\n    @bench \"join\" join($teststr, $teststr)\nend\n\n@benchgroup \"trigonometry\" [\"math\", \"triangles\"] begin\n    # nested groups\n    @benchgroup \"circular\" begin\n        for f in (sin, cos, tan)\n            for x in (0.0, pi)\n                @bench string(f), x $(f)($x)\n            end\n        end\n    end\n\n    @benchgroup \"hyperbolic\" begin\n        for f in (sinh, cosh, tanh)\n            for x in (0.0, pi)\n                @bench string(f), x $(f)($x)\n            end\n        end\n    end\nendnote: Note\nRunning this script directly does not actually run the benchmarks. See the next section."
},

{
    "location": "man/run_benchmarks.html#",
    "page": "Running a benchmark suite",
    "title": "Running a benchmark suite",
    "category": "page",
    "text": ""
},

{
    "location": "man/run_benchmarks.html#PkgBenchmark.benchmarkpkg",
    "page": "Running a benchmark suite",
    "title": "PkgBenchmark.benchmarkpkg",
    "category": "Function",
    "text": "benchmarkpkg(pkg, [ref];\n            script=defaultscript(pkg),\n            require=defaultrequire(pkg),\n            resultsdir=defaultresultsdir(pkg),\n            saveresults=true,\n            tunefile=defaulttunefile(pkg),\n            retune=false,\n            promptsave=true,\n            promptoverwrite=true)\n\nArguments:\n\npkg is the package to benchmark\nref is the commit/branch to checkout for benchmarking. If left out, the package will be benchmarked in its current state.\n\nKeyword arguments:\n\nscript is the script with the benchmarks. Defaults to PKG/benchmark/benchmarks.jl\nrequire is the REQUIRE file containing dependencies needed for the benchmark. Defaults to PKG/benchmark/REQUIRE.\nresultsdir the directory where to file away results. Defaults to PKG/benchmark/.results. Provided the repository is not dirty, results generated will be saved in this directory in a file named <SHA1_of_commit>.jld. And can be used later by functions such as judge. If you choose to, you can save the results manually using writeresults(file, results) where results is the return value of benchmarkpkg function. It can be read back with readresults(file).\nsaveresults if set to false, results will not be saved in resultsdir.\npromptsave if set to false, you will prompted to confirm before saving the results.\ntunefile file to use for tuning benchmarks, will be created if doesn't exist. Defaults to PKG/benchmark/.tune.jld\nretune force a re-tune, saving results to the tune file\npromptsave if set to false, you will prompted to confirm before saving the results.\npromptoverwrite if set to false, will not asked to confirm before overwriting previously saved results for a commit.\n\nReturns:\n\nA BenchmarkGroup object with the results of the benchmark.\n\nExample invocations:\n\nusing PkgBenchmark\n\nbenchmarkpkg(\"MyPkg\") # run the benchmarks at the current state of the repository\nbenchmarkpkg(\"MyPkg\", \"my-feature\") # run the benchmarks for a particular branch/commit/tag\nbenchmarkpkg(\"MyPkg\", \"my-feature\"; script=\"/home/me/mycustombenchmark.jl\", resultsdir=\"/home/me/benchmarkXresults\")\n  # note: its a good idea to set a new resultsdir with a new benchmark script. `PKG/benchmark/.results` is meant for `PKG/benchmark/benchmarks.jl` script.\n\n\n\n"
},

{
    "location": "man/run_benchmarks.html#Running-a-benchmark-suite-1",
    "page": "Running a benchmark suite",
    "title": "Running a benchmark suite",
    "category": "section",
    "text": "Use benchmarkpkg to run benchmarks written using the convention above.benchmarkpkg"
},

{
    "location": "man/run_benchmarks.html#BenchmarkTools.judge",
    "page": "Running a benchmark suite",
    "title": "BenchmarkTools.judge",
    "category": "Function",
    "text": "judge(pkg, [ref], baseline;\n    f=(minimum, minimum),\n    usesaved=(true, true),\n    script=defaultscript(pkg),\n    require=defaultrequire(pkg),\n    resultsdir=defaultresultsdir(pkg),\n    saveresults=true,\n    promptsave=true,\n    promptoverwrite=true)\n\nYou can call showall(results) to see a comparison of all the benchmarks.\n\nArguments:\n\npkg is the package to benchmark\nref optional, the commit to judge. If skipped, use the current state of the package repo.\nbaseline is the commit to compare ref against.\n\nKeyword arguments:\n\nf - tuple of estimator functions - one each for from_ref, to_ref respectively\nuse_saved - similar tuple of flags, if false will not use saved results\nfor description of other keyword arguments, see benchmarkpkg\n\n\n\n"
},

{
    "location": "man/run_benchmarks.html#Comparing-commits-1",
    "page": "Running a benchmark suite",
    "title": "Comparing commits",
    "category": "section",
    "text": "You can use judge to compare benchmark results of two versions of the package.judge"
},

]}
