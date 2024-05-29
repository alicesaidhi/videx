--[[

a lazily evaluated source that only updates at a step or when deemed to be
necessary.

]]

local vide = require(script.Parent.Parent.vide)
local step = require(script.Parent.step)

local effect = vide.effect
local source = vide.source
local untrack = vide.untrack

local within_step = source(false)

local function update_deferred_effects()
	within_step(true)
	within_step(false)
end

step.connect(update_deferred_effects)

--[=[

A lazily evaluated computation. This defers a computation so that it's only
processed when either the next step happens or when the source is read.

@param updater `() -> T` The updater function that will be called to get the new value.
@return `() -> T` A function that returns the value. When ran it will rerun the computation if any dependencies are updated.
@return `() -> T` A function that returns the currently stored value without running the computation even if dependencies are updated.

]=]
local function lazy<T>(updater: () -> T): (() -> T, () -> T)

	local value = source()
	local must_update = source(false)

	local function should_update()
		return must_update() or within_step()
	end

	local updated = false
	local initial = true
	
	effect(function()
		if initial or untrack(should_update) and updated then
			value(updater())
			updated = false
			initial = false
		elseif should_update() == false then
			updated = true
		end
	end)

	return function()
		if updated == true then
			must_update(true)
			-- triggers computation
			must_update(false)
		end

		return value()
	end, value

end

return lazy