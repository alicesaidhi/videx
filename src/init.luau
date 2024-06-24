
local timeline = require(script.timeline)
local vide = require(script.Parent.vide)
local oklab = require(script.oklab)
local step = require(script.step)


export type Source<T> = vide.Source<T>
export type Can<T> = T | () -> T

local connection: RBXScriptConnection?

local videx = {
	store = require(script.store).new,
	null = require(script.store).null,

	boundary = require(script.boundary),

	context = require(script.context),
	
	oklab = oklab,

	step = function(dt: number)
		if connection then
			connection:Disconnect()
			connection = nil
		end

		step.step(dt)
		vide.step(dt)
	end,

	tween = require(script.tween),
	timeline = require(script.timeline).new,
	root_timeline = require(script.timeline).ROOT

}

if game then

	local RunService = game:GetService("RunService")

	if RunService:IsClient() then
		connection = RunService.RenderStepped:Connect(function(dt)
			step.step(dt)
			vide.step(dt)
		end)
	else
		connection = RunService.Heartbeat:Connect(function(dt)
			step.step(dt)
			vide.step(dt)
		end)
	end

end

return table.freeze (setmetatable(videx, vide))