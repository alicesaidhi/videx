local vide = require(script.Parent.Parent.vide)
local defer = require(script.Parent.defer)
local timeline = require(script.Parent.timeline)
local get_value = require(script.get_value)
local easing_styles = require(script.easings)

local source = vide.source
local derive = vide.derive
local action = vide.action
local cleanup = vide.cleanup
local untrack = vide.untrack
local read = vide.read

type source<T> = vide.Source<T>
type canbe<T> = (() -> T) | T
type tweenable = timeline.tweenable
type node = timeline.node
type tween_node = {

	previous_node: tween_node,
	next_node: tween_node,
	root: {_headtween: tween_node},

	instance: Instance,
	key: string,
	start: unknown,
	goal: unknown,

	stagger: canbe<number>,

}
type action = typeof(vide.action(function() end))
type tween = {

	timer: source<number>,
	duration_cycle: source<number>,
	redo: source<number>,
	delay: source<number>,
	yoyo: source<boolean>,
	timescale: source<number>,
	redo_delay: source<number>,
	stagger: {
		amount: source<number>,
		ease: easing_style | (x: number) -> number,
	} | {
		each: source<number>,
		ease: easing_style | (x: number) -> number,
	},

	ease: easing_style | (x: number) -> number,

	alpha: () -> number,
	duration: () -> number,

	_parent: node | false,
	_headtween: tween_node | false,

	to: (tween, to: unknown, stagger: canbe<number>?) -> {[string]: action},
	from: (tween, from: unknown, stagger: canbe<number>?) -> {[string]: action},
	fromto: (tween, from: unknown, to: unknown, stagger: canbe<number>?) -> {[string]: action},

	play: (tween) -> (),
	stop: (tween) -> (),
	seek: (tween, at: number) -> ()

}
type stagger = {

	amount: number?,
	each: number?,
	ease: easing_style | (x: number) -> number,

}

type easing_style = easing_styles.ease_style

export type properties = {

	duration: number?,
	ease: easing_style?,
	redo: number?,
	delay: number?,
	yoyo: boolean?,
	timescale: number?,
	redo_delay: number?,

	stagger: {

		amount: number?,
		each: number?,
		ease: (easing_style | (x: number) -> number)?,
	
	}?
	
}


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

local function create_tween(props: properties)

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

	defer(function()
		local max_stagger = untrack(max_stagger)
		local timer = tween.timer()
		local amount = tween.stagger.amount
		local each = read(tween.stagger.each) or read(amount) / max_stagger
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

	function tween:play()
		timeline.ROOT:add(tween)
	end

	function tween:stop()
		timeline.remove_node(tween._parent)
	end

	function tween:seek(new: number)
		if not tween._parent then
			timeline.ROOT:add(tween)
		end

		assert(tween._parent)

		local root: typeof(timeline.ROOT) = tween._parent.root
		root:add(tween, -new)
	end

	return tween

end

return create_tween