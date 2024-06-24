local vide = require(script.Parent.Parent.vide)
local types = require(script.Parent.types)
local get_value = require(script.get_value)
local easing_styles = require(script.easings)
local root_timeline = require(script.Parent.root_timeline)

local source = vide.source
local derive = vide.derive
local action = vide.action
local cleanup = vide.cleanup
local untrack = vide.untrack
local effect = vide.effect
local read = vide.read

type source<T> = vide.Source<T>
type canbe<T> = (() -> T) | T
type tweenable = types.tweenable
type timeline_node = types.timeline_node
type tween = types.tween
type tween_node = types.tween_node
type ease_style = types.ease_style

local function remove_node_tl_node(node: types.timeline_node)
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


local function remove_node(node: tween_node)
	if node.next_node then
		node.next_node.previous_node = node.previous_node
	end

	if node.previous_node then
		node.previous_node.next_node = node.next_node
	end

	if node.root._headtween == node then
		node.root._headtween = node.next_node
	end
end

local function readu<T>(input: (() -> T) | T)
	return if type(input) == "function" then untrack(input) else input
end

local function create_tween(props: types.tween_properties)
	local ROOT_TIMELINE = root_timeline.root

	local reversing = source(false)
	local update_children = source()
	local tween = {

		timer = source(0),
		duration_cycle = source(props.duration or 1),
		redo = source(props.redo or 0),
		delay = source(props.delay or 0),
		yoyo = source(props.yoyo or false),
		timescale = source(props.timescale or 1),
		redo_delay = source(props.redo_delay or 0),

		stagger = {
			amount = props.stagger and props.stagger.amount and source(props.stagger.amount),
			each = props.stagger and props.stagger.each and (source(props.stagger.each) or not props.stagger.amount and source(0)),
			ease = props.stagger and props.stagger.ease or "linear"
		},

		ease = props.ease,
		
		_parent = false,
		_headtween = false

	} :: tween

	local max_stagger = derive(function()
		update_children()
		local node: false | tween_node = tween._headtween
		local max = 0

		while node do
			max = math.max(math.abs(read(node.stagger)), max)
			node = node.next_node
		end

		return max
	end)

	tween.duration = derive(function()
		local duration = tween.duration_cycle()
		local redo = tween.redo()
		local redo_delay = tween.redo_delay()
		local delay = tween.delay()
		local max = max_stagger()

		if max == 0 then
			return (duration + redo_delay) * (redo + 1) + delay
		else
			local amount = tween.stagger.amount
			local each = read(tween.stagger.each) or read(amount) / max

			if redo == -1 then return math.huge end

			return (duration + redo_delay) * (redo + 1) + delay + max * each
		end
	end)


	local function get_time(input_time: number)
		local current_time = math.clamp(input_time - tween.delay(), 0, tween.duration())
		local duration = tween.duration_cycle()
		local redo = tween.redo()

		-- slow path
		if redo > 0 then
			local redo_delay = tween.redo_delay()
			local duration_and_delay = duration + redo_delay
			local repeated = current_time // duration_and_delay

			if redo ~= -1 then
				repeated = math.clamp(repeated, 0, redo)
			end

			local leftover_time = current_time - repeated * duration_and_delay
			
			if tween.yoyo() and repeated % 2 == 1 then
				leftover_time = duration_and_delay - leftover_time
			end

			current_time = leftover_time - redo_delay
		end


		return math.clamp(current_time, 0, duration)
	end
	
	tween.alpha = function()
		return get_time(tween.timer()) / tween.duration_cycle()
	end

	effect(function()
		local max_stagger = if untrack(max_stagger) == 0 then 1 else untrack(max_stagger)
		local timer = tween.timer()
		local amount = tween.stagger.amount
		local each = read(tween.stagger.each) or (read(amount) and read(amount) / max_stagger) or 1

		if reversing() then timer = tween.duration() - timer end

		local node: false | tween_node = tween._headtween

		local stagger_ease = tween.stagger.ease
		local stagger_ease_fn

		if type(stagger_ease) == "string" then
			stagger_ease_fn = easing_styles[stagger_ease] or easing_styles.linear
		else
			stagger_ease_fn = stagger_ease or easing_styles.linear
		end

		local ease = tween.ease
		local ease_fn

		if type(ease) == "string" then
			ease_fn = easing_styles[ease] or easing_styles.linear
		else
			ease_fn = ease or easing_styles.linear
		end

		while node do
			local stagger_key = stagger_ease_fn(readu(node.stagger) / max_stagger) * max_stagger
			local alpha = (get_time(timer - stagger_key * each)) / tween.duration_cycle()
			local transformed = ease_fn(alpha)

			node.instance[node.key] = get_value(node.start, node.goal, transformed)
			node = node.next_node
		end
	end)

	local function add_node(on: Instance, key: string, from: unknown, to: unknown, stagger: number?)
		local node: tween_node = {
			next_node = tween._headtween,
			previous_node = false,
			root = tween,

			instance = on,
			key = key,
			start = from,
			goal = to,
			stagger = stagger or 0
		}

		if tween._headtween then
			tween._headtween.previous_node = node
		end

		tween._headtween = node
		update_children(node)

		cleanup(function()
			remove_node(node)
			update_children(node)
		end)
	end

	function tween:fromto(from: unknown, to: unknown, stagger: number?)
		local function get_value(key: string)
			return action(function(instance)
				add_node(instance, key, from, to, stagger)
			end, 100_000)
		end

		return setmetatable({}, {__index = function(_, key)
			return get_value(key)
		end})
	end

	function tween:to(to: unknown, stagger: number?)

		local function get_value(key: string)
			return action(function(instance)
				local from = instance[key]
				add_node(instance, key, from, to, stagger)
			end, 100_000)
		end

		return setmetatable({}, {__index = function(_, key)
			return get_value(key)
		end})

	end

	function tween:from(from: unknown, stagger: number?)

		local function get_value(key: string)
			return action(function(instance)
				local to = instance[key]
				instance[key] = from
				add_node(instance, key, from, to, stagger)
			end, 100_000)
		end

		return setmetatable({}, {__index = function(_, key)
			return get_value(key)
		end})

	end

	function tween:reverse()
		local duration = self.duration()
		local time_passed = if not reversing() then duration - self.timer() else self.timer()
		local root_time_passed = ROOT_TIMELINE.timer()

		reversing(true)
		ROOT_TIMELINE:add(self, root_time_passed - time_passed)
	end

	function tween:play()
		local duration = self.duration()
		local time_passed = if reversing() then duration - self.timer() else self.timer()
		local root_time_passed = ROOT_TIMELINE.timer()

		reversing(false)
		ROOT_TIMELINE:add(self, root_time_passed - time_passed)
	end

	function tween:resume()
		local time_passed = self.timer()
		local root_time_passed = ROOT_TIMELINE.timer()

		ROOT_TIMELINE:add(self, root_time_passed - time_passed)
	end

	function tween:pause()
		if self._parent == false then return end
		remove_node_tl_node(self._parent)
	end

	function tween:restart()
		reversing(false)
		ROOT_TIMELINE:add(self)
	end

	function tween:seek(new: number)
		if reversing() then new = self.duration() - new end
		if self._parent ~= false then
			ROOT_TIMELINE:add(self, ROOT_TIMELINE.timer() - new)
		else
			self.timer(new)
		end
	end

	function tween:progress(new: number)
		self:seek(self.duration() * new)
	end

	tween:play()

	return tween

end

return create_tween