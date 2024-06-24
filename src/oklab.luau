--[[

provides functions to handle transformations between sRGB, OKLab and OKLCh

]]

-- each vector3 represents a column
type matrix = {Vector3}
type rgb = Vector3
type lab = Vector3

local function multiply_matrix(matrix: matrix, lab: lab)

	local l = matrix[1] * lab.X
	local a = matrix[2] * lab.Y
	local b = matrix[3] * lab.Z

	return Vector3.new(
		l.X + a.X + b.X,
		l.Y + a.Y + b.Y,
		l.Z + a.Z + b.Z
	)
end

local M_1: matrix = {
	Vector3.new(0.8189330101, 0.0329845436, 0.0482003018),
	Vector3.new(0.3618667424, 0.9293118715, 0.2643662691),
	Vector3.new(-0.1288597137, 0.0361456387, 0.6338517070)
}

local M_2: matrix = {
	Vector3.new(0.2104542553, 0.7936177850, -0.0040720468),
	Vector3.new(1.97799784951, -2.4285922050, 0.4505937099),
	Vector3.new(0.0259040371, 0.7827717662, -0.8086757660)
}

local M_3: matrix = {
	Vector3.new(0.4122214708, 0.2119034982, 0.0883024619),
	Vector3.new(0.5363325363, 0.6806995451, 0.2817188376),
	Vector3.new(0.0514459929, 0.1073969566, 0.6299787005)
}

local M_4: matrix = {
	Vector3.new(1, 1, 1),
	Vector3.new(0.3963377774, -0.1055613458, -0.0894841775),
	Vector3.new(0.2158037573, -0.0638541728, -1.2914855480)
}

local M_5: matrix = {
	Vector3.new(4.0767416621, -1.2684380046, -0.0041960863),
	Vector3.new(-3.3077115913, 2.6097574011, 0.7034186147),
	Vector3.new(0.2309699292, -0.3413193965, 1.7076147010)
}

local function pow(vec: Vector3, pow: number)
	return Vector3.new(vec.X ^ pow, vec.Y ^ pow, vec.Z ^ pow)
end

local function linear_srgb_to_oklab(rgb: Vector3)
	local lms = pow(multiply_matrix(M_3, rgb), (1/3))
	return multiply_matrix(M_2, lms)
end

local function oklab_to_linear_srgb(Lab: Vector3)
	local lms = multiply_matrix(M_4, Lab)
	lms = lms * lms * lms
	return multiply_matrix(M_5, lms)
end

local function oklch_to_oklab(LCh: Vector3)
	return Vector3.new(
		LCh.X,
		LCh.Y * math.cos(math.rad(LCh.Z)),
		LCh.Y * math.sin(math.rad(LCh.Z))
	)
end

local function oklab_to_oklch(Lab: Vector3)
	return Vector3.new(
		Lab.X,
		math.sqrt(Lab.Y ^ 2 + Lab.Z ^ 2), 
		math.atan2(Lab.Z, Lab.Y)
	)
end

local function color3_to_oklab(rgb: Color3)
	return linear_srgb_to_oklab(Vector3.new(rgb.R, rgb.G, rgb.B))
end

local function oklab_to_color3(Lab: Vector3)
	local v = linear_srgb_to_oklab(Lab)
	return Color3.new(v.X, v.Y, v.Z)
end

local function oklch_to_color3(LCh: Vector3)
	return oklab_to_color3(oklch_to_oklab(LCh))
end

return {
	linear_srgb_to_oklab = linear_srgb_to_oklab,
	oklab_to_linear_srgb = oklab_to_linear_srgb,

	oklch_to_oklab = oklch_to_oklab,
	oklab_to_oklch = oklab_to_oklch,

	color3_to_oklab = color3_to_oklab,
	oklab_to_color3 = oklab_to_color3,
	oklch_to_color3 = oklch_to_color3
}