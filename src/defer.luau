--[[

a deferred effect that will only run once the frame ends

]]

local vide = require(script.Parent.Parent.vide)
local step = require(script.Parent.step)

local effect = vide.effect
local source = vide.source
local untrack = vide.untrack

local within_update = source(false)

local function update_deferred_effects()
	within_update(true)
	within_update(false)
end

step.connect(update_deferred_effects)

--[=[

A deferred effect that is only ran at the next step.

@param updater `() -> ()` The function that will be called whenever it needs to update

]=]
local function defer(updater: () -> ())

	local updated = false
	local initial = true

	effect(function()
		if initial or untrack(within_update) and updated then
			updater()
			updated = false
			initial = false
		elseif within_update() == false then
			updated = true
		end
	end)

end

return defer