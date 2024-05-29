--[=[

Handles the stepping logic. Any code that relies on having something run every
single step must be handled here.

]=]

type Node = {

	before: Node | false,
	after: Node | false,

	callback: (...any) -> (...any)

}

local head: Node = {
	before = false,
	after = false,
	callback = function() end
}
local tail = head

--[=[

Connects a callback to the stepping logic, making it run whenever the game steps.
When inside a Roblox environment, this is by default bound to either RunService.PreRender or RunService.PreSimulation,
depending on the availability.

]=]
local function connect(callback: (dt: number) -> ())

	local node = {
		before = false,
		after = false,
		callback = callback
	}

	local connection = {

		reconnect = function()
			tail.after = node
			tail = node
		end,

		disconnect = function()
			if tail == node then
				tail = node.before
			end

			if node.before then
				node.before.after = node.after
			end
			if node.after then
				node.after.before = node.before
			end
		end
		
	}

	connection.reconnect()

	return connection

end

local function step(dt: number)
	local node = head
	
	while node do
		node.callback(dt)
		node = node.after
	end

end

return {
	connect = connect,
	step = step
}