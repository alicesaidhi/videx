
local function lerp_number(a: number, b: number, t: number)
	return a + (b - a) * t
end

--- gets Luau to generate special vector instructions
local function lerp_vector(a: Vector3, b: Vector3, t: number)
	return a + (b - a) * t
end


local lerp = {

	Color3 = function(a: Color3, b: Color3, t: number)
		return a:Lerp(b, t)
	end,

	UDim2 = function(a: UDim2, b: UDim2, t: number)
		return a:Lerp(b, t)
	end,

	Rect = function(a: Rect, b: Rect, t: number)
		local a0, b0, c0, d0 = a.Min.X, a.Min.Y, a.Max.X, a.Max.Y
		local a1, b1, c1, d1 = b.Min.X, b.Min.Y, b.Max.X, b.Max.Y

		return Rect.new(lerp_number(a0, a1, t), lerp_number(b0, b1, t), lerp_number(c0, c1, t), lerp_number(d0, d1, t))
	end,

	UDim = function(a: UDim, b: UDim, t: number)
		return UDim.new(a.Scale + (b.Scale - a.Scale) * t, a.Offset + (b.Offset - b.Offset) * t)
	end,

	Vector2 = function(a: Vector2, b: Vector2, t: number)
		return a:Lerp(b, t)
	end,

	Vector3 = lerp_vector,
	number = lerp_number,

}

local function get_value<T>(a: T, b: T, t: number)

	if type(a) == "number" and type(b) == "number" then
		return lerp_number(a, b, t)
	else
		local lerp_callback = lerp[typeof(a)]
		return lerp_callback(a, b, t)
	end

end

return get_value