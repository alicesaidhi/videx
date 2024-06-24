--!nolint LocalShadow
local types = require(script.Parent.types)
type Pointer = {
	type: "pointer",
	s: "<" | ">"
}

type Operator = {
	type: "operator",
	s: "+=" | "-="
}

type Number = {
	type: "number",
	s: number
}

type Percentage = {
	type: "percentage",
	s: number
}

type Token = Pointer | Operator | Number | Percentage

local function stream(input: string)

	local pos = 0
	local line = 1
	local col = 1

	local function peek(n: number?): string
		local n = n or 1
		return string.sub(input, pos+n, pos+n)
	end

	local function next(): string
		local char = peek()
		pos += 1

		if char == "\n" then line += 1; col = 1
		else col += 1 end

		return char
	end

	local function eof(): boolean
		return peek() == ""
	end

	local function position()
		return {
			pos = pos,
			line = line,
			col = col
		}
	end

	local function croak(msg)
		error(`{msg} ({line}:{col})`, 0)
	end

	return {
		peek = peek,
		next = next,
		eof = eof,
		croak = croak,
		pos = position
	}

end

return function(s: string)
	local input = stream(s)

	local function read_while(predicate: (char: string) -> boolean)
		local str = ""
		while input.eof() == false and predicate(input.peek()) do
			str ..= input.next()
		end
		return str
	end

	local function is_whitespace(char: string)
		return not not string.match(char, "%s")
	end

	local function is_digit(char: string)
		return not not (char == "." or char == "-" or string.match(char, "%d"))
	end

	local function is_pointer(char: string)
		return not not string.match(char, "[<>]")
	end

	local function is_op_char(char: string)
		return not not string.match(char, "[%-=%+]")
	end

	local function read_number()
		local decimal_pointer = false
		local token = read_while(function(char)
			if decimal_pointer and char == "." then return false end
			if char == "." then decimal_pointer = true end
			return is_digit(char)
		end)
		local is_percentage = if input.peek() == "%" then input.next() and true else false
		local n = tonumber(token)

		if not n then
			input.croak(`could not read {token} as number`)
		end

		return if is_percentage then {type = "percentage", s = assert(n) / 100} else {type = "number", s = assert(n)}
	end

	local function read_next(): Token?
		read_while(is_whitespace)
		if input.eof() then return nil end

		local char = input.peek()

		if is_pointer(char) then return {type = "pointer", s = input.next()} end
		if input.peek(2) == "=" and is_op_char(char) then return {type = "operator", s = read_while(is_op_char)} end
		if is_digit(char) then return read_number() end

		input.croak(`cannot understand {char}`)
		error(`cannot understand {char}`)
	end

	local current = nil

	local function next(): Token
		local token = current
		current = nil
		return if token then token else read_next()
	end

	local function peek(): Token
		if current then return current end
		current = read_next()
		return current
	end

	return function(timeline: types.timeline)

		local n = timeline.duration()

		local function parse_number()
			local token = next()

			if token.type == "pointer" then
				local head: false | types.timeline_node = timeline._head
				local v = 0
				local duration = 0
				
				if head then
					duration = head.tween.duration()
					if token.s == "<" then
						v = head.starts_at
					else
						v = head.starts_at + duration
					end
				end

				if peek() == nil then return v end

				if peek().type == "percentage" then
					local t = next()
					assert(t.type == "percentage")
					return v + duration * t.s
				elseif peek().type == "number" then
					local t = next()
					assert(t.type == "number")
					return v + t.s
				end

				return v
			elseif token.type == "number" then
				return token.s
			elseif token.type == "percentage" then
				return n * token.s
			else
				error(`could not parse number, {token.type}`)
			end
		end

		while not input.eof() do
			local token = peek()

			if token.type == "operator" then
				next()
				if token.s == "+=" then
					n += parse_number()
				elseif token.s == "-=" then
					n -= parse_number()
				end
			else
				n = parse_number()
			end

		end

		return n

	end

end