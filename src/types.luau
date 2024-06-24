
local vide = require(script.Parent.Parent.vide)

type source<T> = vide.Source<T>
--- any table considered tweenable.D 
export type tweenable = {
	timer: source<number>,
	--- how long it takes for the tween to finish.
	duration: () -> number,

	--- a tweenable should only have one parent, otherwise the timer will
	--- conflict with the other parent.
	_parent: timeline_node | false
}
--- a node that should be used for parenting
export type timeline_node = {

	previous_node: timeline_node,
	next_node: timeline_node,
	root: {_head: timeline_node},

	starts_at: number,
	tween: tweenable

}


export type tween_properties = {

	duration: number?,
	ease: ease_style?,
	redo: number?,
	delay: number?,
	yoyo: boolean?,
	timescale: number?,
	redo_delay: number?,

	stagger: {

		amount: number?,
		each: number?,
		ease: (ease_style | (x: number) -> number)?,
	
	}?
	
}

export type timeline = {

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
	_head: timeline_node | false,
	--- enabling this disables some calculations.
	_root: boolean,
	--- a parent node 
	_parent: timeline_node | false,

	add: (timeline, tweenable: tweenable, at: string | number?) -> timeline,
	tween: (timeline, tween: tween_properties, at: string | number?) -> tween,

	play: (timeline) -> (),
	pause: (timeline) -> (),
	resume: (timeline) -> (),
	restart: (timeline) -> (),
	reverse: (timeline) -> (),

	seek: (timeline, at: number) -> (),
	progress: (timeline, percentage: number) -> ()

}

type canbe<T> = (() -> T) | T
export type tween_node = {

	previous_node: tween_node,
	next_node: tween_node,
	root: {_headtween: tween_node},

	instance: Instance,
	key: string,
	start: unknown,
	goal: unknown,

	stagger: canbe<number>,

}


type ease_in = "sine.in" | "cubic.in" | "quad.in" | "quart.in" | "quint.in" | "exponential.in" | "circular.in" | "back.in" | "elastic.in" | "bounce.in"
type ease_out = "sine.out" | "cubic.out" | "quad.out" | "quart.out" | "quint.out" | "exponential.out" | "circular.out" | "back.out" | "elastic.out" | "bounce.out"
type ease_inout = "sine.inout" | "cubic.inout" | "quad.inout" | "quart.inout" | "quint.inout" | "exponential.inout" | "circular.inout" | "back.inout" | "elastic.inout" | "bounce.inout"
type ease_outin = "sine.outin" | "cubic.outin" | "quad.outin" | "quart.outin" | "quint.outin" | "exponential.outin" | "circular.outin" | "back.outin" | "elastic.outin" | "bounce.outin"
export type ease_style = "linear" | ease_in | ease_out | ease_inout | ease_outin | string

type action = typeof(vide.action(function() end))
export type tween = {

	timer: source<number>,
	duration_cycle: source<number>,
	redo: source<number>,
	delay: source<number>,
	yoyo: source<boolean>,
	timescale: source<number>,
	redo_delay: source<number>,
	stagger: {
		amount: source<number>,
		ease: ease_style | (x: number) -> number,
	} | {
		each: source<number>,
		ease: ease_style | (x: number) -> number,
	},

	ease: ease_style | (x: number) -> number,

	alpha: () -> number,
	duration: () -> number,

	_parent: timeline_node | false,
	_headtween: tween_node | false,

	to: (tween, to: unknown, stagger: canbe<number>?) -> {[string]: action},
	from: (tween, from: unknown, stagger: canbe<number>?) -> {[string]: action},
	fromto: (tween, from: unknown, to: unknown, stagger: canbe<number>?) -> {[string]: action},

	play: (tween) -> (),
	pause: (tween) -> (),
	resume: (tween) -> (),
	restart: (tween) -> (),
	reverse: (tween) -> (),

	seek: (tween, at: number) -> (),
	progress: (tween, percentage: number) -> ()

}
type stagger = {

	amount: number?,
	each: number?,
	ease: ease_style | (x: number) -> number,

}


return nil