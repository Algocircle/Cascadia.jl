using Cascadia
using Test
using JSON
using Gumbo

function checkstring(elem::HTMLElement{T}) where {T}
    opentag = "<$T"
    for (name,value) in sort(collect(elem.attributes), by=x->x.first)
        opentag *= " $name=\"$value\""
    end
    opentag *= ">"
end

#A function to simplify test artifact creation
P(x) = Cascadia.Parser(x)

@testset "Basic Tests" begin
@test Cascadia.parseName(P("abc")) == "abc"
@test Cascadia.parseName(P("x")) == "x"
@test Cascadia.parseIdentifier(P("abc")) == "abc"
@test Cascadia.parseIdentifier(P("x")) == "x"
@test Cascadia.parseIdentifier(P("-x")) == "-x"
@test Cascadia.parseIdentifier(P("a\\\"b")) == "a\"b"

@test_throws ErrorException Cascadia.parseIdentifier(P("96"))

@test Cascadia.parseEscape(P("\\e9 ")) == "é"
@test Cascadia.parseEscape(P("\\\"b")) == "\""
@test Cascadia.parseIdentifier(P("r\\e9 sumé")) == "résumé"

@test Cascadia.parseString(P("\"abc\"")) == "abc"
@test Cascadia.parseString(P("\"x\"")) == "x"
@test Cascadia.parseString(P("'x'")) == "x"
@test_throws ErrorException Cascadia.parseString(P("'x"))
@test Cascadia.parseString(P("'x\\\r\nx'")) == "xx"
@test Cascadia.parseString(P("\"a\\\"b\"")) == "a\"b"

@test Cascadia.parseInteger(P("90:")) == 90

end

###Selector tests. Load data from file.

selectorTests=JSON.parsefile(joinpath(dirname(@__FILE__), "selectorTests.json"))

cnt = 0
@testset "Selector Test $(d["Selector"])" for d in selectorTests
    c = Selector(d["Selector"])
    @test typeof(c) == Selector
    n=parsehtml(d["HTML"])
    r=eachmatch(c, n.root)
    e = d["Results"]
    @test length(r) == length(e)

    for i in 1:length(r)
        @test lowercase(checkstring(r[i])) == e[i]
    end
end
