local vide = require(script.Parent.Parent.vide)
local root_timeline = require(script.Parent.root_timeline)
local step = require(script.Parent.step)
local tl_lexer = require(script.Parent.tl_lexer)
local tween = require(script.Parent.tween)
local types = require(script.Parent.types)

local source = vide.source
local derive = vide.derive
local untrack = vide.untrack
local effect = vide.effect
local cleanup = vide.cleanup
local root = vide.root

local ROOT_TIMELINE

type source<T> = vide.Source<T>
--- any table considered tweenable.D 
type tweenable = types.tweenable
type node = types.timeline_node
type timeline = types.timeline

local function remove_node(node: node)
	if node.next_node then
		node.next_node.previous_node = node.previous_node
	end

	if node.previous_node then
		node.previous_node.next_node = node.next_node
	end

	if node.root._head == node then
		node.root._head = node.next_node
	end

	node.tween._parent = false
end

local function remove_unnecessary_children(timeline: timeline, current_time: number)

	local function is_within_duration(starts_at: number, tween: tweenable)
		return current_time < starts_at + untrack(tween.duration)
	end

	local node: false | node = timeline._head

	while node do
		if not is_within_duration(node.starts_at, node.tween) then
			node.tween.timer(untrack(node.tween.duration))
			remove_node(node)
		end

		node = node.next_node
	end

end

type props = {
	redo: number?,
	delay: number?,
	yoyo: boolean?,
	timescale: number?,
}

local function create_timeline(props: props)

	local reversing = source(false)
	local update_children = source()
	local timeline = {

		redo = source(props.redo or 0),
		delay = source(props.delay or 0),
		yoyo = source(props.yoyo or false),

		timer = source(0),
		timescale = source(props.timescale or 1),

		duration = source(0),
		duration_cycle = source(0),

		_head = false,
		_auto_remove_children = false,
		_root = false,
		_parent = false

	} :: timeline

	timeline.duration_cycle = derive(function()
		if timeline._root then return end -- disable this calculation if root
		update_children()

		local total_time = 0

		local node: false | node = timeline._head

		while node do
			local starts_at = node.starts_at
			local ends_at = node.tween.duration() + starts_at or 0

			total_time = math.max(total_time, ends_at)
			node = node.next_node
		end
		
		return math.abs(total_time / timeline.timescale())
	end)

	-- updates the duration
	timeline.duration = derive(function()
		if timeline._root then return math.huge end
		return timeline.duration_cycle() * (timeline.redo() + 1) + timeline.delay()
	end)

	-- updates all the timings of all it's childrens when timer is changed
	effect(function()
		-- print("update")
		local time_passed = timeline.timer()
		local delay = timeline.delay()
		local duration = timeline.duration_cycle()
		local redo = timeline.redo()

		if timeline._root == false then
			time_passed = math.clamp(timeline.timer(), 0, timeline.duration())
		end

		time_passed -= delay

		-- redo is higher than 0, slower path that calculates the true time.
		if redo ~= 0 then
			local times_repeated = time_passed // duration

			if redo ~= -1 then
				times_repeated = math.min(times_repeated, redo)
			end

			local leftover_time = time_passed - times_repeated * duration
			
			-- if yoyo, then reverse
			if timeline.yoyo() and times_repeated % 2 == 1 then
				leftover_time = duration - leftover_time
			end

			time_passed = leftover_time
		end

		if timeline._auto_remove_children then
			remove_unnecessary_children(timeline, time_passed)
		end

		if untrack(reversing) then time_passed = duration - time_passed end

		local node: false | node = timeline._head

		while node do
			local starts_at = node.starts_at
			local tween = node.tween
			-- since the duration parameter already tracks how long it takes for
			-- the child tween to finish, we can untrack it here.
			-- ? make sure this wont cause bugs later
			local child_duration = untrack(tween.duration)
			tween.timer(math.clamp(time_passed - starts_at, 0, child_duration))

			node = node.next_node
		end
	end)

	function timeline:add(tweenable: tweenable, starts_at: number | string?)
		starts_at = starts_at or self.timer()
		if type(starts_at) == "string" then
			starts_at = untrack(function()
				return tl_lexer(starts_at)(self)
			end)
		end

		--fixme: remove this in new typechecker
		assert(type(starts_at) == "number")

		if tweenable._parent then remove_node(tweenable._parent) end
		local node: node = {
			next_node = self._head,
			previous_node = false,
			root = self,

			starts_at = starts_at,
			tween = tweenable
		}
		tweenable._parent = node

		if self._head then
			self._head.previous_node = node
		end

		self._head = node

		update_children(tweenable)
	end

	function timeline:tween(props: types.tween_properties, starts_at: number | string?): types.tween
		local tween = tween(props)
		self:add(tween, starts_at)
		return tween
	end

	function timeline:reverse()
		local duration = self.duration()
		local time_passed = if not reversing() then duration - self.timer() else self.timer()
		local root_time_passed = ROOT_TIMELINE.timer()

		reversing(true)
		ROOT_TIMELINE:add(self, root_time_passed - time_passed)
	end

	function timeline:play()
		local duration = self.duration()
		local time_passed = if reversing() then duration - self.timer() else self.timer()
		local root_time_passed = ROOT_TIMELINE.timer()

		reversing(false)
		ROOT_TIMELINE:add(self, root_time_passed - time_passed)
	end

	function timeline:resume()
		local time_passed = self.timer()
		local root_time_passed = ROOT_TIMELINE.timer()

		ROOT_TIMELINE:add(self, root_time_passed - time_passed)
	end

	function timeline:pause()
		if self._parent == false then return end
		remove_node(self._parent)
	end

	function timeline:restart()
		reversing(false)
		ROOT_TIMELINE:add(self)
	end

	function timeline:seek(new: number)
		if reversing() then new = self.duration() - new end
		if self._parent ~= false then
			ROOT_TIMELINE:add(self, ROOT_TIMELINE.timer() - new)
		else
			self.timer(new)
		end
	end

	function timeline:progress(new: number)
		self:seek(self.duration() * new)
	end

	cleanup(function()
		timeline:pause()
	end)
	
	return timeline
end


root(function()
	ROOT_TIMELINE = create_timeline {}

	ROOT_TIMELINE._auto_remove_children = true
	ROOT_TIMELINE._root = true
end)

step.connect(function(dt)
	ROOT_TIMELINE.timer(ROOT_TIMELINE.timer() + ROOT_TIMELINE.timescale() * dt)
end)

root_timeline.root = ROOT_TIMELINE

return {

	create_timeline = create_timeline,
	remove_node = remove_node,

	-- creates a timeline bound to the root timeline.
	new = create_timeline,

	ROOT = ROOT_TIMELINE

}