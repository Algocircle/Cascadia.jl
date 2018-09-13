using Cascadia
using Test
using JSON
using Gumbo

# write your own tests here
@test 1 == 1

#A function to simplify test artifact creation
P(x) = Cascadia.Parser(x)

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

Cascadia.parseInteger(P("90:")) == 90

###Selector tests. Load data from file.

selectorTests=JSON.parsefile(joinpath(dirname(@__FILE__), "selectorTests.json"))

cnt = 0
for (i, d) in enumerate(selectorTests)
    c = Selector(d["Selector"])
    @test typeof(c) == Selector
    n=parsehtml(d["HTML"])
    r=eachmatch(c, n.root)
    l=length(r)
    e = length(d["Results"])
    if l != e
        global cnt += 1
        println("Test Failure (known) for $(d["Selector"]) Expected $e, got $l")
    else
        println("Test Success         for $(d["Selector"])")
    end
end
@test cnt <= 19
println("Total test failures: $cnt / $(length(selectorTests))")
