local vide = require(script.Parent.Parent.vide)
local defer = require(script.Parent.defer)
local lazy = require(script.Parent.lazy)
local step = require(script.Parent.step)

local source = vide.source
local untrack = vide.untrack
local root = vide.root

local ROOT_TIMELINE

type source<T> = vide.Source<T>
--- any table considered tweenable.D 
export type tweenable = {
	timer: source<number>,
	--- how long it takes for the tween to finish.
	duration: () -> number,

	--- a tweenable should only have one parent, otherwise the timer will
	--- conflict with the other parent.
	_parent: node | false
}
--- a node that should be used for parenting
export type node = {

	previous_node: node,
	next_node: node,
	root: {_head: node},

	starts_at: number,
	tween: tweenable

}
type timeline = {

	--- the amount of times to repeat
	redo: source<number>,
	--- the delay from when the timeline starts to when it plays
	delay: source<number>,
	--- when true, will go back to 0 every even repeat
	yoyo: source<boolean>,

	--- the current timer.
	timer: source<number>,
	--- a timescale parameter
	timescale: source<number>,

	--- how long it takes for a timeline to finish
	duration: () -> number,

	--- how long it takes for the tween to perform a single cycle.
	duration_cycle: () -> number,

	--- when true, automatically removes children that no longer need to be
	--- updated.
	_auto_remove_children: boolean,
	--- a list of children that need to be updated
	_head: node | false,
	--- enabling this disables some calculations.
	_root: boolean,
	--- a parent node 
	_parent: node | false,

	add: (timeline, tweenable: tweenable, at: number?) -> timeline,

	play: (timeline) -> (),
	stop: (timeline) -> (),
	seek: (timeline, at: number) -> ()

}

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

local function create_timeline()

	local update_children = source()
	local timeline = {

		redo = source(0),
		delay = source(0),
		yoyo = source(false),

		timer = source(0),
		timescale = source(1),

		duration = source(0),
		duration_cycle = source(0),

		_head = false,
		_auto_remove_children = false,
		_root = false,
		_parent = false

	} :: timeline

	timeline.duration_cycle = lazy(function()
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
		
		return total_time / timeline.timescale()
	end)

	-- updates the duration
	timeline.duration = vide.derive(function()
		return timeline.duration_cycle() * (timeline.redo() + 1) + timeline.delay()
	end)

	-- updates all the timings of all it's childrens when timer is changed
	-- we defer this effect because this should only update at the end of the frame.
	vide.derive(function()
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

	function timeline:add(tweenable: tweenable, starts_at: number?)
		starts_at = starts_at or timeline.timer()

		if tweenable._parent then remove_node(tweenable._parent) end
		local node: node = {
			next_node = self._head,
			previous_node = false,
			root = self,

			starts_at = starts_at,
			tween = tweenable
		}

		if self._head then
			self._head.previous_node = node
		end

		self._head = node

		update_children(tweenable)
	end

	function timeline:play()
		ROOT_TIMELINE:add(timeline)
	end

	function timeline:stop()
		remove_node(timeline._parent)
	end

	function timeline:seek(new: number)
		if not timeline._parent then
			ROOT_TIMELINE:add(timeline)
		end

		assert(timeline._parent)

		local root: timeline = timeline._parent.root
		root:add(timeline, -new)
	end

	return timeline
end


root(function()
	ROOT_TIMELINE = create_timeline()

	ROOT_TIMELINE._auto_remove_children = true
	ROOT_TIMELINE._root = true
	print("root done")
end)

step.connect(function(dt)
	ROOT_TIMELINE.timer(ROOT_TIMELINE.timer() + ROOT_TIMELINE.timescale() * dt)
end)

return {

	create_timeline = create_timeline,
	remove_node = remove_node,

	-- creates a timeline bound to the root timeline.
	new = create_timeline,

	ROOT = ROOT_TIMELINE

}