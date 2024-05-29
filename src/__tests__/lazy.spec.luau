local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(script.Parent.Parent.Parent.vide)
local lazy = require(script.Parent.Parent.lazy)
local step = require(script.Parent.Parent.step)
local jest_globals = require(ReplicatedStorage.dev_packages.jest_globals)

local describe = jest_globals.describe
local test = jest_globals.test
local expect = jest_globals.expect

local function wrap_root(callback: () -> ())
	return function()
		local destroy = vide.mount(callback)
		destroy()
	end
end

describe("defer", function()

	test("should run initially", wrap_root(function()
		
		local value = lazy(function()
			return true
		end)

		expect(value()).toBeTruthy()
	end))

	test("should update every step", wrap_root(function()
		local value = vide.source(0)

		local _, current = lazy(function()
			return value()
		end)

		expect(current()).toBe(0)

		value(1)
		expect(current()).toBe(0)
		step.step(1/60)
		expect(current()).toBe(1)

		value(2)
		expect(current()).toBe(1)
		step.step(1/60)
		expect(current()).toBe(2)

	end))

	test("should update when read", wrap_root(function()
		local value = vide.source(0)

		local lazy_value, current = lazy(function()
			return value()
		end)

		expect(current()).toBe(0)
		value(1)
		expect(current()).toBe(0)
		expect(lazy_value()).toBe(1)
		expect(current()).toBe(1)

	end))

end)