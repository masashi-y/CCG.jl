
using Match

abstract type Category end

abstract type Atomic <: Category end

abstract type Functor{X <: Category, Y <: Category} <: Category end

struct S <: Atomic
    feature :: String
end

struct N <: Atomic
    feature :: String
end

struct NP <: Atomic
    feature :: String
end

struct PP <: Atomic
    feature :: String
end

struct Fwd{X <: Category, Y <: Category} <: Functor{X, Y}
    left  :: X
    right :: Y
end

struct Bwd{X <: Category, Y <: Category} <: Functor{X, Y}
    left  :: X
    right :: Y
end

struct Punct <: Category
    value :: String
end

S() = S("")
N() = N("")
NP() = NP("")
PP() = PP("")

/(x::Category, y::Category) = Fwd(x, y)

|(x::Category, y::Category) = Bwd(x, y)

function atomic_show(io::IO, cat, feature)
    if isempty(feature)
        print(io, "$cat")
    else
        print(io, "$cat[$feature]")
    end
end

Base.show(io::IO, x::S) = atomic_show(io, "S", x.feature)
Base.show(io::IO, x::N) = atomic_show(io, "N", x.feature)
Base.show(io::IO, x::NP) = atomic_show(io, "NP", x.feature)
Base.show(io::IO, x::PP) = atomic_show(io, "PP", x.feature)
Base.show(io::IO, x::Fwd) = print(io, "($(x.left)/$(x.right))")
Base.show(io::IO, x::Bwd) = print(io, "($(x.left)\\$(x.right))")
Base.show(io::IO, x::Punct) = print(io, x.value)

function preprocess(line)
    split(replace(line, r"([\[\]\(\)/\\])", s" \1 "))
end

function atomic(line)
    @match line begin
        "S" => S
        "N" => N
        "NP" => NP
        "PP" => PP
    end
end

function parsestep(items, stack)
    @match items begin
        ["S" || "N" || "NP" || "PP", rest...] => begin
            res, rest = @match rest begin
                ["[", feature, "]", rest...] =>
                     atomic(items[1])(feature), rest
                _ => atomic(items[1])(""), rest
            end
            parsestep(rest, push!(stack, res))
        end
        ["(", rest...] => parsestep(rest, stack)
        ["/", rest...] => parsestep(rest, push!(stack, /))
        ["\\",rest...] => parsestep(rest, push!(stack, |))
        [")", rest...] => begin
            y = pop!(stack)
            f = pop!(stack)
            x = pop!(stack)
            parsestep(rest, push!(stack, f(x, y)))
        end
        [v, rest...] => parsestep(rest, push!(stack, Punct(v)))
        [] => @match length(stack) begin
            1 => return stack[1]
            3 => parsestep([")"], stack)
        end
    end
end

parseline(line) = parsestep(preprocess(line), [])

is_nice(c::Functor{Bwd{S, NP}, NP}) = true
is_nice(c::Category) = false

path = "/Users/masashi-y/depccg/models/tri_headfirst/target.txt"
open(path) do f
    for line in eachline(f)
        line = split(line)[1]
        cat = parseline(line)
        if is_nice(cat)
            println(cat,  " ==> ", is_nice(cat))
        end
    end
end

