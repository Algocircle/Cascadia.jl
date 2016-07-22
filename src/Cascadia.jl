module Cascadia
using Gumbo
# package code goes here

export Selector, nodeText

include("parser.jl")
include("selector.jl")

end # module
