
module Cat

export Category,
       Atomic,
       Functor,
       S,
       N,
       NP,
       PP,
       Fwd,
       Bwd,
       Punct,
       (/),
       (|),
       isatom,
       parse

using Match

abstract type Category end

abstract type Atomic <: Category end

abstract type Functor <: Category end

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

struct Fwd <: Functor
    left  :: Category
    right :: Category
end

struct Bwd <: Functor
    left  :: Category
    right :: Category
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

isatom(::S) = true
isatom(::N) = true
isatom(::NP) = true
isatom(::PP) = true
isatom(::Category) = false

function _show(io::IO, cat, feature)
    if isempty(feature)
        print(io, "$cat")
    else
        print(io, "$cat[$feature]")
    end
end

Base.show(io::IO, x::S) = _show(io, "S", x.feature)
Base.show(io::IO, x::N) = _show(io, "N", x.feature)
Base.show(io::IO, x::NP) = _show(io, "NP", x.feature)
Base.show(io::IO, x::PP) = _show(io, "PP", x.feature)
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

function forward(x, y)
    @match (x, y) begin
        Fwd(s, t), t => s
    end
end

end
