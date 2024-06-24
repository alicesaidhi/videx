# videx
useful utilities for vide that may come useful while designing UI.

## oklab

Performs color transformations to allow you to use OKLab and OKLCh for UI
colors.

## context

Implements a form of dependency injection to save the need from passing data
as props through intermediate components.

Use the `provide` and `consume` api's to consume and process values.

## store

Implements a store object that can be used within and outside vide for managing
state easily. Use `videx.null` to set sources initially to nil

```
Store.new(
	{
		waving = false
	},
	function(self)
		return {

			wave = function()
				self.waving = true
			end

		}
	end
)
```

## tween

Implements a tween class useful for playing beautiful animations

```luau

local tween = videx.tween {
	duration = 2, -- how long a tween takes
	ease = "quad", -- the easing style to use
	redo = 3, -- the amount of times to redo the animation
	delay = 2, -- how long until the animation starts playing
	yoyo = true, -- goes back every second redo if true
	timescale = 1.5, -- how fast time passes for the tween
	redo_delay = 1, -- delay between redo's

	stagger = {
		amount = 2, -- how long it takes until all animations start playing. cannot combine with each
		each = 1, -- how long it takes until the next animation starts playing. cannot combine with amount
		ease = "linear" -- the easing style to use
	}
}

--- by default, tweens will play. we can pause it if we dont wnat that.
tween:pause()

create "Frame" {

	Position = UDim2.fromScale(0.5, 0)
	AnchorPoint = Vector2.new(0.5, 0)

	-- makes the object tween from the current position to the goal
	tween:to(UDim2.fromScale(0.5, 0.5)).Position,
	-- makes the object tween from the current anchorpoint to the goal
	tween:to(Vector2.new(0.5, 0.5)).AnchorPoint
}

```

## timeline

Implements a timeline class useful for coordinating multiple animations to be
played in a given order.

Create a timeline through:
```luau

local tl = videx.timeline {
	redo = 1, -- the amount of times to repeat
	yoyo = true, -- goes back every second redo
	timescale = 1, -- how fast time passes for the timeline
	delay = 1 -- the delay until the animation begins	
}

-- add a tween
local tween1 = tl:tween({
	duration = 2
})
local tween2 = tl:tween({
	duration = 2
}, "<")
--- use a string to tell videx when to start the animation.
--- this is based off of gsap's timeline
--- use tl:add to manually add tweenables to the timeline.

-- control a timeline through the following function
tl:play()
tl:pause()
tl:resume()
tl:reverse()
tl:restart()

tl:seek(2) -- move timeline to 2 seconds
tl:progress(0.5) -- set timeline to be 50% completed
```

