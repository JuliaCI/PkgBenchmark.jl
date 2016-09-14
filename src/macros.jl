export @benchgroup, @bench

const _benchmark_stack = Any[BenchmarkGroup()]

_reset_stack() = (empty!(_benchmark_stack); push!(_benchmark_stack, BenchmarkGroup()))
_top_group() = _benchmark_stack[end]
_push_group!(g) = push!(_benchmark_stack, g)
_pop_group!() = pop!(_benchmark_stack)

macro benchgroup(expr...)
    name = expr[1]
    tags = length(expr) == 3 ? expr[2] : :([])
    grp = expr[end]
    quote
        g = BenchmarkGroup($(esc(tags)))
        _top_group()[$(esc(name))] = g
        _push_group!(g)
        $(esc(grp))
        _pop_group!()
    end
end

macro bench(expr...)
    id = expr[1:end-1]
    bexpr = expr[end]

    quote
        b = @benchmarkable $(esc(bexpr))
        _top_group()[$(esc(id))...] = b
    end
end
