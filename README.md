# Cascadia

[![Build Status](https://travis-ci.org/Algocircle/Cascadia.jl.svg?branch=master)](https://travis-ci.org/Algocircle/Cascadia.jl)

### A CSS Selector library in Julia.

Inspired by, and mostly a direct translation of, the [Cascadia](https://github.com/andybalholm/cascadia) CSS Selector library, written in [Go](https://golang.org/), by [@andybalhom](https://github.com/andybalholm).

This package depends on the [Gumbo.jl](https://github.com/porterjamesj/Gumbo.jl) package by [@porterjamesj](https://github.com/porterjamesj), which is a Julia wrapper around [Google's Gumbo HTML parser library](https://github.com/google/gumbo-parser)

### Usage

Usage is simple. Use `Gumbo` to parse an HTML string into a document, create a `Selector` from a string, and then use `matchall` to get the nodes in the document that match the selector

```julia
using Cascadia
using Gumbo

n=parsehtml("<p id=\"foo\"><p id=\"bar\">")
s=Selector("#foo")
matchall(s, n)
# 1-element Array{Gumbo.HTMLNode,1}:
#  Gumbo.HTMLElement{:p}
```

###Current Status

Most selector types are supported, but a few are still not fully functional. Examples of selectors that currently work, and some that don't  yet, are listed below. 

| Selector | Status        |
|---------------|----------|
| `address` | Works         |
| `*` | Works         |
| `#foo` | Works         |
| `li#t1` | Works         |
| `*#t4` | Works         |
| `.t1` | Works         |
| `p.t1` | Works         |
| `div.teST` | Works         |
| `.t1.fail` | Works         |
| `p.t1.t2` | Works         |
| `p[title]` | Works         |
| `address[title="foo"]` | Works         |
| `[      title        ~=       foo    ]` | Works         |
| `[title~="hello world"]` | Works         |
| `[lang|="en"]` | Works         |
| `[title^="foo"]` | Works         |
| `[title$="bar"]` | Works         |
| `[title*="bar"]` | Works         |
| `.t1:not(.t2)` | Works         |
| `div:not(.t1)` | Works         |
| `li:nth-child(odd)` | Doesn't Work  |
| `li:nth-child(even)` | Doesn't Work  |
| `li:nth-child(-n+2) ` | Doesn't Work  |
| `li:nth-child(3n+1)` | Doesn't Work  |
| `li:nth-last-child(odd)` | Doesn't Work  |
| `li:nth-last-child(even)` | Doesn't Work  |
| `li:nth-last-child(-n+2)` | Doesn't Work  |
| `li:nth-last-child(3n+1)` | Doesn't Work  |
| `span:first-child` | Doesn't Work  |
| `span:last-child` | Doesn't Work  |
| `p:nth-of-type(2)` | Doesn't Work  |
| `p:nth-last-of-type(2)` | Doesn't Work  |
| `p:last-of-type` | Doesn't Work  |
| `p:first-of-type` | Doesn't Work  |
| `p:only-child` | Doesn't Work  |
| `p:only-of-type` | Doesn't Work  |
| `:empty` | Works         |
| `div p` | Works         |
| `div table p` | Works         |
| `div > p` | Works         |
| `p ~ p` | Works         |
| `p + p` | Works         |
| `li, p` | Works         |
| `p +/*This is a comment*/ p` | Works         |
| `p:contains("that wraps")` | Works         |
| `p:containsOwn("that wraps")` | Works         |
| `:containsOwn("inner")` | Works         |
| `p:containsOwn("block")` | Works         |
| `div:has(#p1)` | Works         |
| `div:has(:containsOwn("2"))` | Works         |
| `body :has(:containsOwn("2"))` | Doesn't Work  |
| `body :haschild(:containsOwn("2"))` | Works         |
| `p:matches([\d])` | Works         |
| `p:matches([a-z])` | Works         |
| `p:matches([a-zA-Z])` | Works         |
| `p:matches([^\d])` | Works         |
| `p:matches(^(0|a))` | Works         |
| `p:matches(^\d+$)` | Works         |
| `p:not(:matches(^\d+$))` | Works         |
| `div :matchesOwn(^\d+$)` | Works         |
| `[href#=(fina)]:not([href#=(\/\/[^\/]+untrusted)])` | Doesn't Work  |
| `[href#=(^https:\/\/[^\/]*\/?news)]` | Doesn't Work  |
| `:input` | Works |

