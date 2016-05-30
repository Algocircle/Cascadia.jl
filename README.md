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
