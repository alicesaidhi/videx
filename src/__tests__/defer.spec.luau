local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(script.Parent.Parent.Parent.vide)
local defer = require(script.Parent.Parent.defer)
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
		local did_run = false

		defer(function()
			did_run = true
		end)

		expect(did_run).toBeTruthy()
	end))

	test("should only update every step", wrap_root(function()
		local updates = 0
		local value = vide.source(0)

		defer(function()
			value()
			updates += 1
		end)

		expect(updates).toBe(1)

		value(2)

		expect(updates).toBe(1)

		step.step(1/60)

		expect(updates).toBe(2)

		value(3)
		step.step(1/60)

		expect(updates).toBe(3)

	end))

end)