
--- linear to non linear
local function f(x: number)
	return if x >= 0.0031308 then
		(1.055) * x^(1 / 2.4) - 0.055
	else
		12.92 * x
end

--- non linear to linear
local function f_inv(x: number)
	return if x > 0.04045 then
		((x + 0.055) / (1 + 0.055)) ^ 2.4
	else
		x / 12.92
end

return {
	f = f,
	f_inv = f_inv
}