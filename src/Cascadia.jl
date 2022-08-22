module Cascadia
using Gumbo
using AbstractTrees
# package code goes here

export Selector, nodeText, @sel_str, matchFirst

include("parser.jl")
include("selector.jl")

end # module
