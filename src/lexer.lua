local env = require "env"
local kwords = env.solokeyword
local cooler_kwords = env.keyword

local logging = require "logging"

local function lookupify(src, list)
	list = list or {}

	if type(src) == 'string' then
		for i = 1, src:len() do
			list[src:sub(i, i)] = true
		end
	elseif type(src) == 'table' then
		for i = 1, #src do
			list[src[i]] = true
		end
	end

	return list
end

local f = string.format
local base_ident = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'
local base_digits = '0123456789'
local base_operators = '+-*/'
local base_symbols = '!&~='
local base_misc = '()[]{}<>;:.\\|@#$%?'
local _chars_ = base_ident.. base_digits .. base_operators .. base_symbols

local chars = {
	whitespace = lookupify(' \n\t\r'),
	validEscapes = lookupify('abfnrtv"\'\\'),
	ident = lookupify(
		base_ident.. base_digits .. base_misc, -- tem uns bug e to consertando
		{ --
			start = lookupify(base_ident.. base_digits),
		}
	),

	all = lookupify(
		_chars_,
		{
			start = lookupify(base_ident.. base_digits),
			operator = lookupify(base_operators),
			symbol = lookupify(base_symbols),
		}
	),

	digits = lookupify(
		base_digits,
		{
			hex = lookupify(base_digits .. 'abcdefABCDEF')
		}
	),

	symbols = lookupify(
		base_operators .. base_symbols, {
			bitwise = lookupify(base_symbols),
			operators = lookupify(base_operators)
		}
	)
}

local keywords = lookupify(kwords)

return function (text)
    local pos = 1
    local start = 1
    local buffer = {}
    local lines = {}
	local currentLineLength = 0
	local lineoffset = 0
	local line = 0

    local function look(delta)
		delta = pos + (delta or 0)

		return text:sub(delta, delta)
	end

	local function next()
		pos = pos + 1

		return look(-1)
	end

    local function ttext()
        return text:sub(start, pos-1)
    end

	local function checkgrammar()
		for index, tk in ipairs(buffer) do
			local buf = buffer[index-1]
			local rule
			local err
			if tk.type == 'ident' then
				rule = buf ~= nil and (buf.type=='keyword' or buf.type=="argsep" or buf.type=="operator")
				err = f('what the fuck identifier "%s" is doing on line %s', tk.value, line+1)
			elseif tk.type == 'argsep' then
				rule = buf~=nil and (buf.type=='ident')
				err = f('what the fuck the argsep on line %s is going to separate?', line+1)
			elseif tk.type == 'bitwise' then
				rule = buf~=nil and buf.type=='keyword'
				err = f('what the fuck "%s" on line %s is going to do?', tk.value, line+1)
			elseif tk.type == 'operator' then
				rule = buf~=nil and buf.type=='keyword'
				err = f('what the fuck "%s" on line %s is going to do?', tk.value, line+1)
			elseif tk.type == 'eof' then
				rule = false
				err = f('what the fuck is "%s" on line %s?', tk.value, line+1)
			end

			logging.assert(rule, err or 'wheres the buffer?')
		end
	end

    local function tokenize(t, value)
        value = value or ttext()

		local tk = {
			type = t,
			value = value,
			posFirst = start - lineoffset,
			posLast = pos - 1 - lineoffset,
			line = line
		}

		if tk.value ~= '' then
			buffer[#buffer + 1] = tk
		end

		currentLineLength = currentLineLength + #value
		start = pos

		checkgrammar()

		return tk
    end

    local function newline()
		line = line + 1
        lines[line] = buffer
        buffer = {}

        next()
        tokenize('newline', '\n')
        lineoffset = lineoffset + currentLineLength
		currentLineLength = 0
    end

    local function eatwhitespace()
        while true do
			local char = look()

			if char == '\n' then
				newline()
			elseif chars.whitespace[char] then
				pos = pos + 1
			else
				break
			end
		end

		tokenize('whitespace', '')
    end

	local function word()
		while chars.ident[look()] do
			pos = pos + 1
		end
		return ttext()
	end

	local function phrase()
		while true do
			local char2 = next()

			if char2 == '' or char2 == '\n' then
				pos = pos - 1
				return char2, ttext()
			end
		end
	end

    while true do
        eatwhitespace()

        local char = next()

        if char == '' then
            break
		elseif char == ',' then
			tokenize('argsep', char)
		elseif char == ';' then
			pos = pos + 1

			local c, phr = phrase()

			tokenize('comment', phr)

			if c == '\n' then
				newline()
			end
        elseif chars.ident.start[char] then
            local ident = word()

            if keywords[ident] then
				tokenize('keyword', ident)
			else
				tokenize('ident', ident)
			end
        elseif chars.symbols[char] then
            local ident = word()

			if #ident > 1 then
				tokenize('ident', ident)
			else
				if chars.symbols.operators[char] then
					tokenize('operator', char)
				elseif chars.symbols.bitwise[char] then
					tokenize('bitwise', char)
				end
			end
        else
            tokenize('eof', char)
        end
    end

    lines[#lines + 1] = buffer
	checkgrammar()

    return lines
end