
include("category.jl")
include("ccgbank.jl")

path = "/Users/masashi-y/ccgbank/ccgbank_1_1/data/AUTO/00/wsj_0001.auto"
res = CCGBank.readfile(path)
for t in res
    println(t)
end

