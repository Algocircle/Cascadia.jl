module Cascadia
using Gumbo
# package code goes here

export Selector, nodeText, @sel_str

include("parser.jl")
include("selector.jl")

end # module
