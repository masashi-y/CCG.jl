
module CCGBank

export Tree,
       Node,
       Leaf,
       CCG,
       parseline,
       readfile

using Match
using Cat
import Cat.Category

abstract type Tree end

struct Node <: Tree
    cat :: Category
    head :: Int
    nodes :: Vector{Tree}
end

struct Leaf <: Tree
    word :: String
    tag :: String
    cat :: Category
    dep :: String
end

struct CCG <: Tree
    name :: String
    tree :: Tree
end

function Base.show(io::IO, x::Node)
    sibl = length(x.nodes)
    cs = join(map(string, x.nodes), " ")
    print(io, "(<T $(x.cat) $(x.head) $sibl> $cs )")
end

function Base.show(io::IO, x::Leaf)
    print(io, "(<L $(x.cat) $(x.tag) $(x.tag) $(x.word) $(x.dep)>)")
end

function Base.show(io::IO, x::CCG)
    println(io, x.name)
    print(io, x.tree)
end

function preprocess(line)
    split(replace(line, r"<|>", " "))
end


function parsestep(items, stack)
    @match items begin
        [] => return stack[1]
        ["(", "L", cat, pos, _, word, dep, _, rest...] => begin
            push!(stack, Leaf(word, pos, Cat.parseline(cat), dep))
            parsestep(rest, stack)
        end
        ["(", "T", cat, head, _, rest...] => begin
            push!(stack, cs -> Node(Cat.parseline(cat), parse(head), cs))
            parsestep(rest, stack)
        end
        [")", rest...] => begin
            c1 = pop!(stack)
            f = pop!(stack)
            if isa(f, Function)
                cs = [c1]
            else
                c2 = f
                f = pop!(stack)
                cs = [c2, c1]
            end
            push!(stack, f(cs))
            parsestep(rest, stack)
        end
    end
end

parseline(line) = parsestep(preprocess(line), [])

function readfile(file)
    res = []
    open(file) do f
        while !eof(f)
            name = readline(f)
            parse = readline(f) |> parseline
            push!(res, CCG(name, parse))
        end
    end
    res
end

end
