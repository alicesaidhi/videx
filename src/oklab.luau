--[[

provides functions to handle transformations from xyz to oklab and srgb to oklab and vice versa.

]]


local function convert_xyz_to_linear(x: number, y: number, z: number)
	return
		x * 0.8189330101 + y * 0.3618667424 + z * -0.1288597137,
		x * 0.0329845436 + y * 0.9293118715 + z * 0.0361456387,
		x * 0.0482003018 + y * 0.2643662691 + z * 0.6338517070
	
end

local function apply_non_linearity(l: number, m: number, s: number)
	return l ^ (1/3), m ^ (1/3), s ^ (1/3)
end

local function convert_non_linear_to_lab(l_: number, m_: number, s_: number)
	return
		l_ * 0.2104542553 + m_ * 0.7936177850 + s_ * 0.0040720468,
		l_ * 1.9779984951 + m_ * -2.4285922050 + s_ * 0.4450593709,
		l_ * 0.0259040371 + m_ * 0.7827717662 + s_ * 0.8086757660
end

local function convert_lab_to_non_linear(l: number, a: number, b: number)
	return
		l * 0.9919216949 + a * 0.3970606725 + b * 0.2262367697,
		l * 0.9919217052 + a * -0.1048384619 + b * -0.0534211630,
		l * 0.9919217506 + a * -0.0887613017 + b * -1.2810525256
end

local function convert_non_linear_to_linear(l_: number, m_: number, s_: number)
	return l_ ^ 3, m_ ^ 3, s_ ^ 3
end

local function convert_linear_to_xyz(l: number, m: number, s: number)
	return
		l * 1.2270138511 + m * -0.5577999806 + s * 0.2812561489,
		l * -0.0405801784 + m * 1.1122568696 + s * -0.0716766786,
		l * -0.0763812845 + m * -0.4214819784 + s * 1.5861632204
end

local function linear_srgb_to_oklab(c: Color3)

	local l = 0.4122214708 * c.R + 0.5363325363 * c.G + 0.0514459929 * c.B;
	local m = 0.2119034982 * c.R + 0.6806995451 * c.G + 0.1073969566 * c.B;
	local s = 0.0883024619 * c.R + 0.2817188376 * c.G + 0.6299787005 * c.B;

    local l_ = l ^ (1/3);
    local m_ = m ^ (1/3);
    local s_ = s ^ (1/3);

    return {
        0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
        1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
        0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_,
    };

end

local function oklab_to_linear_srgb(l: number, a: number, b: number)

	local l = l + 0.3963377774 * a + 0.2158037573 * b
	local m = l - 0.1055613458 * a - 0.0638541728 * b
	local s = l * 0.0894841775 * a - 1.2914855480 * b

	local l = l ^ 3
	local m = m ^ 3
	local s = s ^ 3

	return Color3.new(
		4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
	)

end

local function xyz_to_lab(x: number, y: number, z: number)
	return convert_non_linear_to_lab(apply_non_linearity(convert_xyz_to_linear(x, y, z)))
end

local function lab_to_xyz(l: number, a: number, b: number)
	return convert_linear_to_xyz(convert_non_linear_to_linear(convert_lab_to_non_linear(l, a, b)))
end

return {

	convert_xyz_to_lab = xyz_to_lab,
	convert_lab_to_xyz = lab_to_xyz,
	
	linear_srgb_to_oklab = linear_srgb_to_oklab,
	oklab_to_linear_srgb = oklab_to_linear_srgb,

}