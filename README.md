# Cascadia

[![Build Status](https://travis-ci.org/Algocircle/Cascadia.jl.svg?branch=master)](https://travis-ci.org/Algocircle/Cascadia.jl)
[![Latest Version](https://juliahub.com/docs/Cascadia/version.svg)](https://juliahub.com/ui/Packages/Cascadia/Pq6Fi/)
[![Pkg Eval](https://juliahub.com/docs/Cascadia/pkgeval.svg)](https://juliahub.com/ui/Packages/Cascadia/Pq6Fi/)
[![Dependents](https://juliahub.com/docs/Cascadia/deps.svg)](https://juliahub.com/ui/Packages/Cascadia/Pq6Fi/?t=2)

### A CSS Selector library in Julia.

Inspired by, and mostly a direct translation of, the [Cascadia](https://github.com/andybalholm/cascadia) CSS Selector library, written in [Go](https://golang.org/), by [@andybalhom](https://github.com/andybalholm).

This package depends on the [Gumbo.jl](https://github.com/porterjamesj/Gumbo.jl) package by [@porterjamesj](https://github.com/porterjamesj), which is a Julia wrapper around [Google's Gumbo HTML parser library](https://github.com/google/gumbo-parser)

### Usage

Usage is simple. Use `Gumbo` to parse an HTML string into a document, create a `Selector` from a string, and then use `eachmatch` to get the nodes in the document that match the selector. Alternatively, use `sel"<selector string>"` to do the same thing as `Selector`. The `eachmatch` function returns an array of elements which match the selector. If no match is found, a zero element array is returned. For unique matches, the array contains one element. Thus, check the length of the array to test whether a selector matches.

```julia
using Cascadia
using Gumbo

n=parsehtml("<p id=\"foo\"><p id=\"bar\">")
s=Selector("#foo")
sm = sel"#foo"
eachmatch(s, n.root)
# 1-element Array{Gumbo.HTMLNode,1}:
#  Gumbo.HTMLElement{:p}

eachmatch(sm, n.root)
# 1-element Array{Gumbo.HTMLNode,1}:
#  Gumbo.HTMLElement{:p}
```

__Note:__ The top level matching function name has changed from `matchall` in `v0.6` to `eachmatch` in `v0.7` and higher to reflect the change in Julia base.

### Webscraping Example

The primary use case for this library is to enable webscraping -- the automatic extraction of information from html pages. As an example, consider the following code, which returns a list of questions that have been tagged with `julia-lang` on StackOverflow.

```julia
using Cascadia, Gumbo, HTTP

r = HTTP.get("http://stackoverflow.com/questions/tagged/julia-lang")
h = parsehtml(String(r.body))

qs = eachmatch(Selector(".question-summary"),h.root)

println("StackOverflow Julia Questions (votes  answered?  url)")

for q in qs
    votes = nodeText(eachmatch(Selector(".votes .vote-count-post "), q)[1])
    answered = length(eachmatch(Selector(".status.answered"), q)) > 0
    href = eachmatch(Selector(".question-hyperlink"), q)[1].attributes["href"]
    println("$votes  $answered  http://stackoverflow.com$href")
end
```

This code produces the following output:

```
StackOverflow Julia Questions (votes  answered?  url)

0  false  http://stackoverflow.com/questions/59361325/how-to-get-a-rolling-window-regression-in-julia
0  true  http://stackoverflow.com/questions/59356818/how-i-translate-python-code-into-julia-code
-2  false  http://stackoverflow.com/questions/59354720/how-to-fix-this-error-in-julia-throws-same-error-for-all-packages-not-found-i
-1  true  http://stackoverflow.com/questions/59354407/julia-package-for-geocoding
1  false  http://stackoverflow.com/questions/59350631/jupyter-lab-precompile-error-for-kernel-1-0-after-adding-kernel-1-3
0  true  http://stackoverflow.com/questions/59348461/genie-framework-does-not-install-under-julia-1-2
...
2  true  http://stackoverflow.com/questions/59300202/julia-package-install-fail-with-please-specify-by-known-name-uuid
2  false  http://stackoverflow.com/questions/59297379/how-do-i-transfer-my-packages-after-installing-a-new-julia-version
```

Note that this returns the elements on the first page of the query results. Getting the values from subsequent pages is left as an exercise for the reader.


### Current Status

This library should work with almost all CSS selectors. Please [raise an issue](https://github.com/Algocircle/Cascadia.jl/issues) if you find any that don't work. However, note that [CSS pseudo elements](https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-elements) are not yet supported. 

Specifically, the following selector types are tested, and known to work.

| Selector |
|---------------|
| `address` |
| `*` |
| `#foo` |
| `li#t1` |
| `*#t4` |
| `.t1` |
| `p.t1` |
| `div.teST` |
| `.t1.fail` |
| `p.t1.t2` |
| `p[title]` |
| `address[title="foo"]` |
| `[title ~= foo]` |
| `[title~="hello world"]` |
| `[lang\|="en"]` |
| `[title^="foo"]` |
| `[title$="bar"]` |
| `[title*="bar"]` |
| `.t1:not(.t2)` |
| `div:not(.t1)` |
| `li:nth-child(odd)` |
| `li:nth-child(even)` |
| `li:nth-child(-n+2)` |
| `li:nth-child(3n+1)` |
| `li:nth-last-child(odd)` |
| `li:nth-last-child(even)` |
| `li:nth-last-child(-n+2)` |
| `li:nth-last-child(3n+1)` |
| `span:first-child` |
| `span:last-child` |
| `p:nth-of-type(2)` |
| `p:nth-last-of-type(2)` |
| `p:last-of-type` |
| `p:first-of-type` |
| `p:only-child` |
| `p:only-of-type` |
| `:empty` |
| `div p` |
| `div table p` |
| `div > p` |
| `p ~ p` |
| `p + p` |
| `li, p` |
| `p +/*This is a comment*/ p` |
| `p:contains("that wraps")` |
| `p:containsOwn("that wraps")` |
| `:containsOwn("inner")` |
| `p:containsOwn("block")` |
| `div:has(#p1)` |
| `div:has(:containsOwn("2"))` |
| `body :has(:containsOwn("2"))` |
| `body :haschild(:containsOwn("2"))` |
| `p:matches([\d])` |
| `p:matches([a-z])` |
| `p:matches([a-zA-Z])` |
| `p:matches([^\d])` |
| `p:matches(^(0\|a))` |
| `p:matches(^\d+$)` |
| `p:not(:matches(^\d+$))` |
| `div :matchesOwn(^\d+$)` |
| `[href#=(fina)]:not([href#=(\/\/[^\/]+untrusted)])` |
| `[href#=(^https:\/\/[^\/]*\/?news)]` |
| `:input` |
