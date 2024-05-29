--!optimize 2

local Math = math

local function linear(x: number)
	return x
end

local function sine_in(x: number)
	return 1 - math.cos((x * math.pi) / 2)
end

local function sine_out(x: number)
	return math.sin((x * math.pi) / 2)
end

local function sine_inout(x: number)
	return -(math.cos(math.pi * x) - 1) / 2
end

local function quad_in(x: number)
	return x * x
end

local function quad_out(x: number)
	return 1 - quad_in(1 - x)
end

local function quad_inout(x: number)
	return if x < 0.5 then 2 * quad_in(x) else 1 - quad_out(-2 * x + 2) / 2
end

local function cubic_in(x: number)
	return x * x * x
end

local function cubic_out(x: number)
	return 1 - cubic_in(1 - x)
end

local function cubic_inout(x: number)
	return if x < 0.5 then 2 * cubic_in(x) else 1 - cubic_out(-2 * x + 2) / 2
end

local function quart_in(x: number)
	return x * x * x * x
end

local function quart_out(x: number)
	return 1 - quart_in(1 - x)
end

local function quart_inout(x: number)
	return if x < 0.5 then 2 * quart_in(x) else 1 - quart_out(-2 * x + 2) / 2
end

local function quint_in(x: number)
	return x * x * x * x * x
end

local function quint_out(x: number)
	return 1 - quint_in(1 - x)
end

local function quint_inout(x: number)
	return if x < 0.5 then 2 * quint_in(x) else 1 - quint_out(-2 * x + 2) / 2
end

local function exponential_in(x: number)
	return x == 0 and 0 or math.pow(2, 10 * x - 10)
end

local function exponential_out(x: number)
	return 1 - exponential_in(1 - x)
end

local function exponential_inout(x: number)
	return x == 0
	and 0
	or x == 1
	and 1
	or x < 0.5 and Math.pow(2, 20 * x - 10) / 2
	or (2 - Math.pow(2, -20 * x + 10)) / 2;
end

local function circular_in(x: number)
	return 1 - Math.sqrt(1 - Math.pow(x, 2))
end

local function circular_out(x: number)
	return Math.sqrt(1 - Math.pow(x - 1, 2))
end

local function circular_inout(x: number)
	return x < 0.5
	and (1 - Math.sqrt(1 - Math.pow(2 * x, 2))) / 2
	or (Math.sqrt(1 - Math.pow(-2 * x + 2, 2)) + 1) / 2
end

local function back_in(x: number)
	local c1 = 1.70158
	local c3 = c1 + 1
	return  c3 * x * x * x - c1 * x * x
end

local function back_out(x: number)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2)
end

local function back_inout(x: number)
	local c1 = 1.70158
	local c2 = c1 * 1.525

	return if x < 0.5 then
		(math.pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
	else (math.pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
end

local function elastic_in(x: number)
	local c4 = (2 * math.pi) / 3
	return x == 0 and 0 or x == 1 and 1 or -math.pow(2, 10*x-10) * math.sin((x*10-10.75)*c4) 
end

local function elastic_out(x: number)
	local c4 = (2 * math.pi) / 3
	return x == 0 and 0 or x == 1 and 1 or -math.pow(2, -10*x) * math.sin((x*10-0.75)*c4) 
end

local function elastic_inout(x: number)
	local c5 = (2 * math.pi) / 4.5
	return if x == 0 or x == 1 then x elseif x < 0.5 then
		-(math.pow(2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2
	else (math.pow(2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) / 2 + 1
end

local function bounce_out(x: number)
	local n1 = 7.5625
	local d1 = 2.75

	return if x < 1 / d1 then n1 * x * x
		elseif x < 2 / d1 then n1 * (x - 1.5 / d1) ^ 2 + 0.75
		elseif x < 2.5 / d1 then n1 * (x - 2.5 / d1) ^ 2 + 0.9375
		else n1 * (x - 2.625 / d1) ^ 2 + 0.984375
end

local function bounce_in(x: number)
	return 1 - bounce_out(1 - x)
end

local function bounce_inout(x: number)
	return if x < 0.5 then (1 - bounce_out(1 - 2 * x)) / 2 else (1 + bounce_out(2 * x - 1)) / 2
end


type ease_in = "sine.in" | "cubic.in" | "quad.in" | "quart.in" | "quint.in" | "exponential.in" | "circular.in" | "back.in" | "elastic.in" | "bounce.in"
type ease_out = "sine.out" | "cubic.out" | "quad.out" | "quart.out" | "quint.out" | "exponential.out" | "circular.out" | "back.out" | "elastic.out" | "bounce.out"
type ease_inout = "sine.inout" | "cubic.inout" | "quad.inout" | "quart.inout" | "quint.inout" | "exponential.inout" | "circular.inout" | "back.inout" | "elastic.inout" | "bounce.inout"
type ease_outin = "sine.outin" | "cubic.outin" | "quad.outin" | "quart.outin" | "quint.outin" | "exponential.outin" | "circular.outin" | "back.outin" | "elastic.outin" | "bounce.outin"

export type ease_style = "linear" | ease_in | ease_out | ease_inout | ease_outin | string

local function generate_step(steps: number)
	steps += 1
	local step_size = 1 / steps

	return function(x: number)
		local steps_made = math.round(x / step_size)
		return steps_made * step_size
	end

end

return setmetatable ({

	["linear"] = linear,

	["sine.in"] = sine_in,
	["sine.out"] = sine_out,
	["sine.inout"] = sine_inout,
	["sine.outin"] = function(x: number) return 1 - sine_inout(1 - x) end,

	["quad.in"] = quad_in,
	["quad.out"] = quad_out,
	["quad.inout"] = quad_inout,
	["quad.outin"] = function(x: number) return 1 - quad_inout(1 - x) end,

	["cubic.in"] = cubic_in,
	["cubic.out"] = cubic_out,
	["cubic.inout"] = cubic_inout,
	["cubic.outin"] = function(x: number) return 1 - cubic_inout(1 - x) end,

	["quart.in"] = quart_in,
	["quart.out"] = quart_out,
	["quart.inout"] = quart_inout,
	["quart.outin"] = function(x: number) return 1 - quart_inout(1 - x) end,

	["quint.in"] = quint_in,
	["quint.out"] = quint_out,
	["quint.inout"] = quint_inout,
	["quint.outin"] = function(x: number) return 1 - quint_inout(1 - x) end,

	["exponential.in"] = exponential_in,
	["exponential.out"] = exponential_out,
	["exponential.inout"] = exponential_inout,
	["exponential.outin"] = function(x: number) return 1 - exponential_inout(1 - x) end,

	["circular.in"] = circular_in,
	["circular.out"] = circular_out,
	["circular.inout"] = circular_inout,
	["circular.outin"] = function(x: number) return 1 - circular_inout(1 - x) end,

	["back.in"] = back_in,
	["back.out"] = back_out,
	["back.inout"] = back_inout,
	["back.outin"] = function(x: number) return 1 - back_inout(1 - x) end,

	["elastic.in"] = elastic_in,
	["elastic.out"] = elastic_out,
	["elastic.inout"] = elastic_inout,
	["elastic.outin"] = function(x: number) return 1 - elastic_inout(1 - x) end,

	["bounce.in"] = bounce_in,
	["bounce.out"] = bounce_out,
	["bounce.inout"] = bounce_inout,
	["bounce.outin"] = function(x: number) return 1 - bounce_inout(1 - x) end,

}, {
	__index = function(_, key: string)
		local ease_key, num = string.match(key, "(.*)%.([0-9]*)")
		assert(ease_key and num, "did not match any easing style")
		num = tonumber(num) or 3

		if ease_key == "steps" then
			return generate_step(num)
		end

		error("did not match any easing style")

	end
})