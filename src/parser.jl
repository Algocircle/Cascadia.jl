
# a parser for CSS selectors
mutable struct Parser
	s::String  # the source text
	i::Int64    # the current position
end

Parser(s) = Parser(String(s), 1)

# // parseEscape parses a backslash escape.
function parseEscape(p::Parser)
  if length(p.s) < p.i+2 || p.s[p.i] != '\\'
    parseError(p, "invalid escape sequence")
  end
  start = p.i + 1
  c = p.s[start]

  if  c == '\r' || c == '\n' || c == '\f'
	  parseError(p, "escaped line ending outside string")
  elseif hexDigit(c)
	  # unicode escape (hex)
	  local i
	  i = start
	  while  i < p.i+6 && i <= length(p.s) && hexDigit(p.s[i])
		  i += 1
	  end
	  v = parse(UInt, p.s[start:i], base=16)
	  if length(p.s) >= i
		  if  p.s[i] == '\r'
			  i += 1
			  if length(p.s) >= i && p.s[i] == '\n'
				  i += 1
			  end
		  elseif  p.s[i] == ' ' || p.s[i] == '\t' || p.s[i] == '\n' || p.s[i] == '\f'
			  i += 1
		  end
	  end
	  p.i = i
	  return string(Char(v))
  end

  #Return the literal character after the backslash.
  result = p.s[start : start]
  p.i += 2
  return result

end



hexDigit(c::Char) = '0' <= c && c <= '9' || 'a' <= c && c <= 'f' || 'A' <= c && c <= 'F'



# // nameStart returns whether c can be the first character of an identifier
# // (not counting an initial hyphen, or an escape sequence).
nameStart(c::Char) = 'a' <= c && c <= 'z' || 'A' <= c && c <= 'Z' || c == '_' || UInt32(c) > 127


# // nameChar returns whether c can be a character within an identifier
# // (not counting an escape sequence).
nameChar(c::Char) = 'a' <= c && c <= 'z' || 'A' <= c && c <= 'Z' || c == '_' || UInt32(c) > 127 ||
	c == '-' || '0' <= c && c <= '9'


#// parseIdentifier parses an identifier.
function parseIdentifier(p::Parser) #->String
	startingDash=false
	if length(p.s) >= p.i && p.s[p.i] == '-'
		startingDash = true
		p.i = p.i + 1
	end
	if length(p.s) < p.i ; parseError(p, "expected identifier, found EOF instead"); end
	c = p.s[p.i]
	if !(nameStart(c) || c == '\\'); parseError(p, "expected identifier, found $c instead"); end
	result = parseName(p)
	if startingDash
		result = "-" * result
	end
	return result
end



# // parseName parses a name (which is like an identifier, but doesn't have
# // extra restrictions on the first character).
function parseName(p::Parser) #->String
	i = p.i
	result = ""
	while i <= length(p.s)
		c = p.s[i]
		if nameChar(c)
			start = i
			while i <= length(p.s) && nameChar(p.s[i])
				i += 1
			end
			result = result * p.s[start:i-1]
		elseif c == '\\'
			p.i = i
			val = parseEscape(p)
			i = p.i
			result = result * val
		else
			break
		end
	end
	if result == ""
		parseError(p, "expected name, found EOF instead")
	end
	p.i = i
	return result
end



#// parseString parses a single- or double-quoted string.
function parseString(p::Parser) #-> String
	i = p.i
	if length(p.s) < i + 2
		parseError(p, "expected string, found EOF instead")
	end
	qt = p.s[i]
	i = i+1
	result = ""
	while i <= length(p.s)
		if  p.s[i]  ==  '\\'
			if length(p.s) > i+1
				c = p.s[i+1]
				if p.s[i+1] == '\r'
					if length(p.s) > i+2 && p.s[i+2] == '\n'
						i += 3
						continue
					end
				end
				if p.s[i+1] == '\n' || p.s[i+1] == '\f'
					i += 2
					continue
				end
			end
			p.i = i
			val = parseEscape(p)
			i = p.i
			result = result * val
		elseif p.s[i] ==  qt
			break
		elseif p.s[p.i] ==  '\r' || p.s[p.i] == '\n' || p.s[p.i] ==  '\f'
			parseError(p, "unexpected end of line in string")
		else
			start = i
			while i <= length(p.s)
				c = p.s[i]
				if c == qt || c == '\\' || c == '\r' || c == '\n' || c == '\f'
					break
				end
				i += 1
			end
			result = result *  p.s[start:i-1]
		end
	end
	if i >= length(p.s)+1
		parseError(p, "EOF in string")
	end

	#// Consume the final quote.
	i += 1

	p.i = i
	return result
end



#// parseRegex parses a regular expression; the end is defined by encountering an
#// unmatched closing ')' or ']' which is not consumed
function parseRegex(p::Parser) #-> Regex
	i = p.i
	if length(p.s) < i+2
		parseError(p, "expected regular expression, found EOF instead")
	end
	#number of open parens or brackets;
	#when it becomes negative, finished parsing regex
	open=0
	while i <= length(p.s)
		if p.s[i] == '(' || p.s[i] == '['
			open += 1
		elseif p.s[i] == ')' || p.s[i] == ']'
			open -= 1
			if open<0
				break
			end
		end
		i += 1
	end
	if i > length(p.s)
		parseError(p, "EOF in regular expression")
	end
	rx = Regex(p.s[p.i:i-1])
	p.i=i
	return rx
end



#// skipWhitespace consumes whitespace characters and comments.
#// It returns true if there was actually anything to skip.
function skipWhitespace(p::Parser) #->boolean
	i = p.i
	while i <= length(p.s)
		if p.s[i] == ' ' || p.s[i] == '\t' || p.s[i] == '\r' || p.s[i] == '\n' || p.s[i] == '\f'
			i += 1
			continue
		elseif p.s[i] == '/'
			if startswith(p.s[p.i:end], "/*")
				ends,endl = something(findnext("*/", p.s, i+length("/*")), 0:-1)
				if endl != -1
					i = endl+1
					continue
				end
			end
		end
		break
	end
	if i > p.i
		p.i = i
		return true
	end
	return false
end



#// consumeParenthesis consumes an opening parenthesis and any following
#// whitespace. It returns true if there was actually a parenthesis to skip.
function consumeParenthesis(p::Parser) #->boolean
	if p.i <= length(p.s) && p.s[p.i] == '('
		p.i += 1
		skipWhitespace(p)
		return true
	end
	return false
end



#// consumeClosingParenthesis consumes a closing parenthesis and any preceding
#// whitespace. It returns true if there was actually a parenthesis to skip.
function consumeClosingParenthesis(p::Parser) #->boolean
	i=p.i
	skipWhitespace(p)
	if p.i<=length(p.s) && p.s[p.i]==')'
		p.i += 1
		return true
	end
	p.i = i
	return false
end



#// parseTypeSelector parses a type selector (one that matches by tag name).
function parseTypeSelector(p::Parser) #->Selector
	tag = parseIdentifier(p)
	return typeSelector(tag)
end



#// parseIDSelector parses a selector that matches by id attribute.
function parseIDSelector(p::Parser)
	if p.i > length(p.s)
		parseError(p, "expected class selector (.class), found EOF instead")
	end
	if p.s[p.i] != '#'
		parseError(p, "expected id selector (#id), found '$(p.s[p.i])' instead")
	end
	p.i += 1
	id  = parseName(p)

	return attributeEqualsSelector("id", id)
end



#// parseClassSelector parses a selector that matches by class attribute.
function parseClassSelector(p::Parser) #-> Selector
	if p.i > length(p.s)
		parseError(p, "expected class selector (.class), found EOF instead")
	end
	if p.s[p.i] != '.'
		parseError(p, "expected class selector (.class), found '$(p.s[p.i])' instead")
	end

	p.i += 1
	class  = parseIdentifier(p)

	return attributeIncludesSelector("class", class)
end



#// parseAttributeSelector parses a selector that matches by attribute value.
function parseAttributeSelector(p) #-> Selector
	if p.i > length(p.s)
		parseError(p, "expected attribute selector ([attribute]), found EOF instead")
	end
	if p.s[p.i] != '['
		parseError(p, "expected attribute selector ([attribute]), found '$(p.s[p.i])' instead")
	end
	p.i += 1
	skipWhitespace(p)
	key = parseIdentifier(p)
	skipWhitespace(p)
	if p.i > length(p.s)
		parseError(p, "unexpected EOF in attribute selector")
	end
	if p.s[p.i] == ']'
		p.i += 1
		return attributeExistsSelector(key)
	end
	if p.i+2 > length(p.s)
		parseError(p, "unexpected EOF in attribute selector")
	end
	op = p.s[p.i : p.i+1]
	if op[1] == '='
		op = "="
	elseif op[2] != '='
		parseError(p, "expected equality operator, found '$op' instead")
	end
	p.i += length(op)

	skipWhitespace(p)
	if p.i > length(p.s)
		parseError(p, "unexpected EOF in attribute selector")
	end
	local val
	local rx
	if op == "#="
		rx = parseRegex(p)
	else
		if p.s[p.i] ==  '\'' || p.s[p.i]== '"'
			val =  parseString(p)
		else
			val = parseIdentifier(p)
		end
	end

	skipWhitespace(p)
	if p.i > length(p.s)
		parseError(p, "unexpected EOF in attribute selector")
	end
	if p.s[p.i] != ']'
		parseError(p, "expected ']', found '$(p.s[p.i])' instead" )
	end
	p.i += 1

	if op == "="
		return attributeEqualsSelector(key, val)
	elseif op == "~="
		return attributeIncludesSelector(key, val)
	elseif op == "|="
		return attributeDashmatchSelector(key, val)
	elseif op == "^="
		return attributePrefixSelector(key, val)
	elseif op == "\$="
		return attributeSuffixSelector(key, val)
	elseif op == "*="
		return attributeSubstringSelector(key, val)
	elseif op == "#="
		return attributeRegexSelector(key, rx)
	end

	parseError(p, "attribute operator $op is not supported")

end



const expectedParenthesis = "expected '(' but didn't find it"
const expectedClosingParenthesis = "expected ')' but didn't find it"
const unmatchedParenthesis = "unmatched '('"

#// parsePseudoclassSelector parses a pseudoclass selector like :not(p).
function parsePseudoclassSelector(p::Parser) #-> Selector
	if p.i > length(p.s)
		parseError(p, "expected pseudoclass selector (:pseudoclass), found EOF instead")
	end
	if p.s[p.i] != ':'
		parseError(p, "expected attribute selector (:pseudoclass), found '$(p.s[p.i])' instead")
	end
	p.i += 1
	name = parseIdentifier(p)
	name = lowercase(name)

	if name == "not" || name =="has" || name == "haschild"
		if !consumeParenthesis(p)
			parseError(p, expectedParenthesis)
		end
		sel = parseSelectorGroup(p)
		if !consumeClosingParenthesis(p)
			parseError(p, expectedClosingParenthesis)
		end
		if name == "not"
			return negatedSelector(sel)
		elseif name == "has"
			return hasDescendantSelector(sel)
		elseif name == "haschild"
			return hasChildSelector(sel)
		end
	elseif  name =="contains" || name == "containsown"
		if !consumeParenthesis(p)
			parseError(p, expectedParenthesis)
		end
		if p.i > length(p.s)
			parseError(p, unmatchedParenthesis)
		end
		val = ""
		if p.s[p.i] ==  '\'' || p.s[p.i] ==  '"'
			val   = parseString(p)
		else
			val  = parseIdentifier(p)
		end

		val = lowercase(val)
		skipWhitespace(p)
		if p.i > length(p.s)
			parseError(p, "unexpected EOF in pseudo selector")
		end
		if !consumeClosingParenthesis(p)
			parseError(p, expectedClosingParenthesis)
		end

		if  name ==  "contains"
			return textSubstrSelector(val)
		elseif name ==  "containsown"
			return ownTextSubstrSelector(val)
		end
	elseif name == "matches" || name == "matchesown"
		if !consumeParenthesis(p)
			parseError(p, expectedParenthesis)
		end
		rx  = parseRegex(p)

		if p.i > length(p.s)
			parseError(p, "unexpected EOF in pseudo selector")
		end
		if !consumeClosingParenthesis(p)
			parseError(p, expectedClosingParenthesis)
		end

		if name == "matches"
			return textRegexSelector(rx)
		elseif name == "matchesown"
			return ownTextRegexSelector(rx)
		end
	elseif name == "nth-child" || name == "nth-last-child" || name == "nth-of-type" || name == "nth-last-of-type"
		if !consumeParenthesis(p)
			parseError(p, expectedParenthesis)
		end
		a, b = parseNth(p)
		if !consumeClosingParenthesis(p)
			parseError(p, expectedClosingParenthesis)
		end
		return nthChildSelector(a, b,
				name == "nth-last-child" || name == "nth-last-of-type",
				name == "nth-of-type" || name == "nth-last-of-type")
	elseif name == "first-child"
		return nthChildSelector(0, 1, false, false)
	elseif name == "last-child"
		return nthChildSelector(0, 1, true, false)
	elseif name == "first-of-type"
		return nthChildSelector(0, 1, false, true)
	elseif name == "last-of-type"
		return nthChildSelector(0, 1, true, true)
	elseif name == "only-child"
		return onlyChildSelector(false)
	elseif name == "only-of-type"
		return onlyChildSelector(true)
	elseif name == "input"
		return inputSelector()
	elseif name == "empty"
		return emptyElementSelector()
	end
	parseError(p, "unknown pseudoclass : $name")
end



#// parseInteger parses a  decimal integer.
function parseInteger(p) #-> Int
	i = p.i
	start = i
	while i <= length(p.s) && '0' <= p.s[i] && p.s[i] <= '9'
		i += 1
	end
	if i==start
		parseError(p, "expected integer, but didn't find it.")
	end
	p.i=i
	val = parse(Int, p.s[start:i-1])
	return val
end



# // parseNth parses the argument for :nth-child (normally of the form an+b).
function parseNth(p::Parser) # -> (a,b)::(Int, Int)
	if p.i > length(p.s)
		@goto eof
	end
	c=p.s[p.i]
	if c == '-'
		p.i+= 1
		@goto negativeA
	elseif c == '+'
		p.i+= 1
		@goto positiveA
	elseif c=='0'||c=='1'||c=='2'||c=='3'||c=='4'||c=='5'||c=='6'||c=='7'||c=='8'||c=='9'
		@goto positiveA
	elseif c=='n'||c=='N'
		a=1
		p.i+= 1
		@goto readN
	elseif c=='o'||c=='O'||c=='e'||c=='E'
		id = parseName(p)
		id = lowercase(id)
		if id == "odd"
			return 2, 1
		elseif id =="even"
			return 2, 0
		end
		error("expected 'odd' or 'even', but found '$s' instead", id)
	else
		@goto invalid
	end

	@label positiveA
	if p.i > length(p.s)
		@goto eof
	end
	c=p.s[p.i]

	if c=='0'||c=='1'||c=='2'||c=='3'||c=='4'||c=='5'||c=='6'||c=='7'||c=='8'||c=='9'
		a = parseInteger(p)
		@goto readA
	elseif c=='n'||c=='N'
		a = 1
		p.i += 1
		@goto readN
	else
		@goto invalid
	end

	@label negativeA
	if p.i > length(p.s)
		@goto eof
	end
	c=p.s[p.i]
	if c=='0'||c=='1'||c=='2'||c=='3'||c=='4'||c=='5'||c=='6'||c=='7'||c=='8'||c=='9'
		a = parseInteger(p)
		a = -a
		@goto readA
	elseif c=='n'||c=='N'
		a = -1
		p.i += 1
		@goto readN
	else
		@goto invalid
	end

	@label readA
	if p.i > length(p.s)
		@goto eof
	end
	c=p.s[p.i]
	if c=='n'||c=='N'
		p.i += 1
		@goto readN
	else
		#// The number we read as a is actually b.
		return 0, a
	end

	@label readN
	skipWhitespace(p)
	if p.i > length(p.s)
		@goto eof
	end
	c=p.s[p.i]
	if c == '+'
		p.i += 1
		skipWhitespace(p)
		b = parseInteger(p)
		return a, b
	elseif c ==  '-'
		p.i += 1
		skipWhitespace(p)
		b = parseInteger(p)
		return a, -b
	else
		return a, 0
	end

	@label eof
	parseError(p, "unexpected EOF while attempting to parse expression of form an+b")

	@label invalid
	parseError(p, "unexpected character while attempting to parse expression of form an+b")
end




# // parseSimpleSelectorSequence parses a selector sequence that applies to
# // a single element.
function parseSimpleSelectorSequence(p::Parser) #-> Selector
	result = nothing
	if p.i > length(p.s)
		parseError(p, "expected selector, found EOF instead")
	end
	c = p.s[p.i]
	if c == '*'
		#// It's the universal selector. Just skip over it, since it doesn't affect the meaning.
		p.i += 1
	elseif c=='#' || c=='.' || c=='[' || c==':'
		#// There's no type selector. Wait to process the other till the main loop.
	else
		r = parseTypeSelector(p)
		result = r
	end
	while p.i <= length(p.s)
		c=p.s[p.i]
		if c == '#'
			ns  = parseIDSelector(p)
		elseif c ==  '.'
			ns = parseClassSelector(p)
		elseif c == '['
			ns = parseAttributeSelector(p)
		elseif c == ':'
			ns = parsePseudoclassSelector(p)
		else
			break
		end
		if result == nothing
			result = ns
		else
			result = intersectionSelector(result, ns)
		end
	end
	if result == nothing
		result = trueSelector()
	end
	return result
end



# // parseSelector parses a selector that may include combinators.
function parseSelector(p::Parser) # -> Selector
	skipWhitespace(p)
	result = parseSimpleSelectorSequence(p)
	while true
		if skipWhitespace(p)
			combinator = ' '
		end
		if p.i > length(p.s)
			return result
		end
		c = p.s[p.i]
		if c == '+' || c == '>' || c =='~'
			combinator = p.s[p.i]
			p.i += 1
			skipWhitespace(p)
		elseif c == ',' || c==')'
			# // These characters can't begin a selector, but they can legally occur after one.
			return result
		end
		if UInt32(combinator) == 0; return; end
		c = parseSimpleSelectorSequence(p)

		if combinator ==  ' '
			result = descendantSelector(result, c)
		elseif combinator ==  '>'
			result = childSelector(result, c)
		elseif combinator == '+'
			result = siblingSelector(result, c, true)
		elseif combinator ==  '~'
			result = siblingSelector(result, c, false)
		end
	end
	parseError(p, "Unreachable")
end


#// parseSelectorGroup parses a group of selectors, separated by commas.
function parseSelectorGroup(p::Parser) # -> Selector
	result = parseSelector(p)
	while p.i <= length(p.s)
		if p.s[p.i] != ','
			return result
		end
		p.i += 1
		c=parseSelector(p)
		result =  unionSelector(result, c)
	end
	return result
end


function parseError(p::Parser, msg)
	spc=" "
	crt="^"
	error("$msg\n  $(p.s)\n$(repeat(spc, p.i+1)*crt)")
end
