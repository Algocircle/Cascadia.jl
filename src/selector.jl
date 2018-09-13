

#// the Selector type, and functions for creating them

#// A Selector is a function which tells whether a node matches or not.
mutable struct Selector
    f::Function
end

(s::Selector)(n::HTMLNode) = s.f(n)
(s::Selector)(n::NullNode) = false

firstChild(n::HTMLElement) = isempty(n.children) ? nothing : n.children[1]
firstChild(n::HTMLText) = nothing
firstChild(n::HTMLDocument) = n.root

function nextSibling(n::HTMLNode)
     p=n.parent
     l=length(p.children)
     i=findall(x->x===n, p.children)
     if isempty(i) || i[1]==l
         return nothing
     else
        return p.children[i[1]+1]
    end
end

function prevSibling(n::HTMLNode)
     p=n.parent
     l=length(p.children)
     i=findall(x->x===n, p.children)
     if isempty(i) || i[1]==1
         return nothing
     else
        return p.children[i[1]-1]
    end
end


#type Selector func(*html.Node) bool

#// hasChildMatch returns whether n has any child that matches a.
function hasChildMatch(n::HTMLNode, a::Selector)
    for c = Gumbo.children(n)
        if a(c); return true; end
    end
    return false
end



#// hasDescendantMatch performs a depth-first search of n's descendants,
#// testing whether any of them match a. It returns true as soon as a match is
#// found, or false if no match is found.
function hasDescendantMatch(n::HTMLNode, a::Selector)
    for c in Gumbo.children(n)
        if typeof(c) == HTMLText; return a(c); end
        for cc in PostOrderDFS(c)
            if a(cc); return true; end
        end
    end
    return false
end



#// Compile parses a selector and returns, if successful, a Selector object
#// that can be used to match against html.Node objects.

function Selector(sel::AbstractString) #->Selector
    p=Parser(sel)
    compiled = parseSelectorGroup(p)
    if p.i < length(sel)
        error("Parsing $(p.s): $(length(sel) - p.i) bytes left over")
    end
    return compiled
end

#// A macro wrapper around the Selector function, turns a string literal
#// into a Selector object
macro sel_str(sel::AbstractString)
  Selector(sel)
end

# // MustCompile is like Compile, but panics instead of returning an error.


#// eachmatch returns a slice of the nodes that match the selector,
#// from n and its children.
function Base.eachmatch(s::Selector, n::HTMLNode ) #->HTMLNode[]
    return matchAllInto(s, n, HTMLNode[])
end

if VERSION >= v"0.7-" && VERSION < v"1.0-"
function Base.matchall(s::Selector, n::HTMLNode )
    Base.depwarn("use eachmatch instead of matchall", :matchall)
    eachmatch(s, n)
end
end


function matchAllInto(s::Selector, n::HTMLNode, storage::Array)
    for c in PreOrderDFS(n)
        if s(c); push!(storage, c); end
    end
    return storage
end



#// Match returns true if the node matches the selector.
Base.match(s::Selector, n::HTMLNode) = s(n)



#// MatchFirst returns the first node that matches s, from n and its children.
function matchFirst(s::Selector, n::HTMLNode)
    for c in PreOrderDFS(n)
        if s(c); return c; end
    end
    return nothing
end



#// Filter returns the nodes in nodes that match the selector.
function Base.filter(s::Selector, nodes::Vector{T}) where T<:HTMLNode
    result = HTMLNode[]
    for n in nodes
        if s(n); append(result, n); end
    end
    return result
end



#// typeSelector returns a Selector that matches elements with a given tag name.
function typeSelector(tg) #->Selector
    tg=lowercase(tg)
    return Selector() do n::HTMLNode
        if !(typeof(n) <: HTMLElement); return false; end
        lowercase(string(tag(n))) == tg
    end
end



#// toLowerASCII returns s with all ASCII capital letters lowercased.


#// attributeSelector returns a Selector that matches elements
#// where the attribute named key satisifes the function f.
function attributeSelector(f::Function, key::AbstractString) #->bool
    key = lowercase(key)
    return Selector() do n::HTMLNode
            if !(typeof(n) <: HTMLElement); return false; end
            for (k,v) in attrs(n)
                if k==key && f(v); return true; end
            end
            return false
    end
end



#// attributeExistsSelector returns a Selector that matches elements that have
#// an attribute named key.
function attributeExistsSelector(key::AbstractString)
    return attributeSelector(key) do s
        return true
    end
end



#// attributeEqualsSelector returns a Selector that matches elements where
#// the attribute named key has the value val.
function attributeEqualsSelector(key::AbstractString, val::AbstractString)
    return attributeSelector(key) do s
        return s==val
    end
end



#// attributeIncludesSelector returns a Selector that matches elements where
#// the attribute named key is a whitespace-separated list that includes val.
function attributeIncludesSelector(key::AbstractString, val::AbstractString)
    return attributeSelector(key) do s
        for y in split(s)
            if y==val; return true; end
        end
        return false
    end
end


#// attributeDashmatchSelector returns a Selector that matches elements where
#// the attribute named key equals val or starts with val plus a hyphen.
function attributeDashmatchSelector(key::AbstractString, val::AbstractString) #-> Selector
    return attributeSelector(key) do s
        if s==val; return true; end
        if length(s) <= length(val); return false; end
        if s[1:length(val)] == val && s[length(val)+1] == '-'
            return true
        end
        return false
    end
end



#// attributePrefixSelector returns a Selector that matches elements where
#// the attribute named key starts with val.
function attributePrefixSelector(key::AbstractString, val::AbstractString) #-> Selector
    return attributeSelector(key) do s
        return startswith(s, val)
    end
end



#// attributeSuffixSelector returns a Selector that matches elements where
#// the attribute named key ends with val.
function attributeSuffixSelector(key::AbstractString, val::AbstractString) #->Selector
    return attributeSelector(key) do s
        return endswith(s, val)
    end
end



#// attributeSubstringSelector returns a Selector that matches nodes where
#// the attribute named key contains val.
function attributeSubstringSelector(key::AbstractString, val::AbstractString) #-> Selector
    return attributeSelector(key) do s
        return occursin(val, s)
    end
end



#// attributeRegexSelector returns a Selector that matches nodes where
#// the attribute named key matches the regular expression rx
function attributeRegexSelector(key::AbstractString, rx::Regex) #->Selector
    return attributeSelector(key) do s
        return occursin(rx, key)
    end
end



#// intersectionSelector returns a selector that matches nodes that match
#// both a and b.
function intersectionSelector(a::Selector, b::Selector) #->Selector
    return Selector() do n::HTMLNode
        return a(n) && b(n)
    end
end



#// unionSelector returns a selector that matches elements that match
#// either a or b.
function unionSelector(a::Selector, b::Selector) #->Selector
    return Selector() do n::HTMLNode
        return a(n) || b(n)
    end
end



#// negatedSelector returns a selector that matches elements that do not match a.
function negatedSelector(a::Selector) #->Selector
    return Selector() do n::HTMLElement
        return !a(n)
    end
end



#// writeNodeText writes the text contained in n and its descendants to b.
function writeNodeText(io, n::HTMLNode)
    for c in PreOrderDFS(n)
        if typeof(c) == HTMLText
            write(io, c.text)
        end
    end
end




#// nodeText returns the text contained in n and its descendants.
nodeText(n::HTMLNode) = sprint(writeNodeText, n)



#// nodeOwnText returns the contents of the text nodes that are direct
#// children of n.
function nodeOwnText(n::HTMLNode) #->String
    b=IOBuffer()
    for c in n.children
        if typeof(c) == HTMLText
            write(b, c.text)
        end
    end
    return String(take!(copy(b)))
end

nodeOwnText(n::HTMLText) = ""



#// textSubstrSelector returns a selector that matches nodes that
#// contain the given text.
function textSubstrSelector(val::AbstractString) #->Selector
    return Selector() do n::HTMLNode
        text = lowercase(nodeText(n))
        return occursin(val, text)
    end
end



#// ownTextSubstrSelector returns a selector that matches nodes that
#// directly contain the given text
function ownTextSubstrSelector(val::AbstractString) #->Selector
    return Selector() do n::HTMLNode
        text = lowercase(nodeOwnText(n))
        return occursin(val, text)
    end
end



#// textRegexSelector returns a selector that matches nodes whose text matches
#// the specified regular expression
function textRegexSelector(rx::Regex) #->Selector
    return Selector() do n::HTMLNode
        return occursin(rx, nodeText(n))
    end
end



#// ownTextRegexSelector returns a selector that matches nodes whose text
#// directly matches the specified regular expression
function ownTextRegexSelector(rx::Regex) #->Selector
    return Selector() do n::HTMLNode
        return occursin(rx, nodeOwnText(n))
    end
end



#// hasChildSelector returns a selector that matches elements
#// with a child that matches a.
function hasChildSelector(a::Selector) #->Selector
    return Selector() do n::HTMLNode
        return hasChildMatch(n, a)
    end
end



#// hasDescendantSelector returns a selector that matches elements
#// with any descendant that matches a.
function hasDescendantSelector(a::Selector) #->Selector
    return Selector() do n::HTMLNode
        return hasDescendantMatch(n, a)
    end
end



#// nthChildSelector returns a selector that implements :nth-child(an+b).
#// If last is true, implements :nth-last-child instead.
#// If ofType is true, implements :nth-of-type instead.
function nthChildSelector(a::Int, b::Int, last::Bool, ofType::Bool) #->Selector
    return Selector() do n::HTMLNode
        if !(typeof(n) <: HTMLElement); return false; end
        parent = n.parent
        if parent == NullNode; return false; end
        i=-1
        count=0
        for c in Gumbo.children(parent)
            if typeof(c) != HTMLElement || (ofType && tag(c) != tag(n))
                continue
            end
            count += 1
            if c == n
                i=count
                if c !== children(parent)[end]
                    break
                end
            end
        end
        if i==-1
            # This shouldn't happen, since n should always be one of its parent's children.
            return false
        end
        if c===children(parent)[end]
            i = count -i + 1
        end

        i -= b
		if a == 0
			return i == 0
		end

		return rem(i, a) == 0 && i/a >= 0
    end
end



#// onlyChildSelector returns a selector that implements :only-child.
#// If ofType is true, it implements :only-of-type instead.
function onlyChildSelector(ofType::Bool) #-> Selector
    return Selector() do n::HTMLNode
        if !(typeof(n) <: HTMLElement); return false; end
        parent = n.parent
        if parent == nothing  || parent == NullNode; return false; end
        count = 0
        for c in Gumbo.children(parent)
            if typeof(c) != HTMLElement || (oftype && tag(c) != tag(n))
                continue
            end
            count += 1
            if count > 1; return false; end
        end
        return count == 1
    end
end



#// inputSelector is a Selector that matches input, select, textarea and button elements.
function inputSelector()
    return Selector() do n
        return inputSelectorFn(n)
    end
end

function inputSelectorFn(n::HTMLElement) #-> bool
    x=string(tag(n))
    return x=="input" || x=="select" || x=="textarea" || x=="button"
end

inputSelectorFn(n::HTMLNode) = false



#// emptyElementSelector is a Selector that matches empty elements.
function emptyElementSelector()
    return Selector() do n
        return emptyElementSelectorFn(n)
    end
end

function emptyElementSelectorFn(n::HTMLElement) #-> boolean
    for c in Gumbo.children(n)
        if typeof(c) <: HTMLElement || typeof(c) == HTMLText
            return false
        end
    end
    return true
end

emptyElementSelectorFn(n::HTMLNode) = false



#// descendantSelector returns a Selector that matches an element if
#// it matches d and has an ancestor that matches a.
function descendantSelector(a::Selector, d::Selector) #-> Selector
    return Selector() do n::HTMLNode
        if !d(n)
            return false
        end
        p = n.parent
        while p!=nothing && typeof(p) != NullNode
            if a(p)
                return true
            end
            p=p.parent
        end
        return false
    end
end




#// childSelector returns a Selector that matches an element if
#// it matches d and its parent matches a.
function childSelector(a::Selector, d::Selector) #-> Selector
    return Selector() do n::HTMLNode
        return d(n) && a(n.parent)
    end
end



#// siblingSelector returns a Selector that matches an element
#// if it matches s2 and in is preceded by an element that matches s1.
#// If adjacent is true, the sibling must be immediately before the element.
function siblingSelector(s1::Selector, s2::Selector, adjacent::Bool) #-> Selector
    return Selector() do n::HTMLNode
        if !s2(n); return false; end
        if adjacent
            m = prevSibling(n)
            while m!= nothing
                if typeof(m) == HTMLText #|| typeof(m) == HTMLComment
                    continue
                end
                return s1(m)
                m = prevSibling(m)
            end
            return false
        end
        #// Walk backwards looking for element that matches s1
        c = prevSibling(n)
        while c!= nothing
            if s1(c) ; return true; end
            c=prevSibling(c)
        end
        return false
    end
end




trueSelector() = Selector((n) -> return true)
