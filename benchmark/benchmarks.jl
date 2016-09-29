using PkgBenchmark
using UnicodePlots

@benchgroup "utf8" ["string", "unicode"] begin
    teststr = String(join(rand(MersenneTwister(1), 'a':'d', 10^4)))
    @bench "replace" replace($teststr, "a", "b")
    @bench "join" join($teststr, $teststr)

    @benchgroup "plots" begin
        @bench "fnplot" lineplot([sin, cos], -π/2, 2pi)
    end
end

@benchgroup "trigonometry" ["math", "triangles"] begin
    # nested groups
    @benchgroup "circular" begin
        for f in (sin, cos, tan)
            for x in (0.0, pi)
                @bench string(f), x $(f)($x)
            end
        end
    end

    @benchgroup "hyperbolic" begin
        for f in (sinh, cosh, tanh)
            for x in (0.0, pi)
                @bench string(f), x $(f)($x)
            end
        end
    end
end
