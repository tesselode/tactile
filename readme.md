Tactile
=======

Tactile is an input library for LÖVE that bridges the gap between different input methods and types. In Tactile, there is no distinction between buttons and analog controls - controls are both buttons and axes at the same time.

Example
-------
```lua
Control = {
  Horizontal = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'leftx'))
    :addButtonPair(tactile.keys('a', 'left'), tactile.keys('d', 'right')),
  Vertical = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'lefty'))
    :addButtonPair(tactile.keys('w', 'up'), tactile.keys('s', 'down')),
  Fire = tactile.newControl()
    :addAxis(tactile.gamepadAxis(1, 'triggerleft'))
    :addAxis(tactile.gamepadAxis(1, 'triggerright'))
    :addButton(tactile.gamepadButtons(1, 'a'))
    :addButton(tactile.keys 'x')
}

function love.update(dt)
  -- movement - using axis inputs
  local inputVector = vector(Control.Horizontal(), Control.Vertical())
  player.pos = player.pos + player.speed * inputVector * dt

  -- firing - using button inputs
  if Control.Fire:isDown() then
    player:shoot()
  end
end
```

How it works
------------
"But that doesn't make sense!" you say. "How can a control be both an axis and a button? That's weird!" You're right it's weird! Let me explain:
- Controls hold a value anywhere between -1 and 1.
  - Analog inputs, like gamepad analog sticks, are mapped directly to the value.
  - Button inputs, like face buttons and keys, send a value of exactly -1, 0, or 1, depending on whether they're pressed or not.
- Controls also behave as buttons. The button is considered to be pressed if the axis value surpasses the deadzone.

It's an unusual approach to controls, but it makes working with analog and binary inputs extremely easy.

Installation
------------
Place tactile.lua somewhere in your project. To use it, do:
```lua
local tactile = require 'path.to.tactile'
```

API
---
### `Control = tactile.newControl()`
Creates and returns a new control.

### `Control:addAxis(f)`
Adds an axis detector to the control.
- `f` (function) - an axis detector. Axis detectors are functions that return a number between -1 and 1.

### `Control:addButton(f)`
Adds a button detector to the control.
- `f` (function) - a button detector. Button detectors are functions that return a boolean value.

### `Control:addButtonPair(negative, positive)`
Adds a pair of button detectors to the control. The negative button detector will be mapped to -1, and the positive button detector will be mapped to 1.
- `negative` (function) - the negative button detector.
- `positive` (function) - the positive button detector.

### `Control:getValue()`
Returns the current axis value of the control. The control checks each axis and button detector in the order they were added. Any detector that has a non-zero value will overwrite the previous one, so the detector that should have the highest precedence should be added last. Button detectors are mapped to 1, and button pairs are mapped to -1 and 1.

### ```Control:isDown(dir)```
Returns whether the control is down or not. The control is considered to be down if its absolute value is greater than the deadzone.
- `dir` (optional) - set this to -1 or 1 to check if the control is down in a certain direction. For example, if the control has a button pair detector where the negative button is the left arrow key and the positive button is the right arrow key, `Control:isDown(-1)` will only return true if the left arrow key is down.

### ```Control:pressed(dir)```
Returns whether the control was pressed this frame.
- `dir` (optional) - the direction to check.

### ```Control:released(dir)```
Returns whether the control was released this frame.
- `dir` (optional) - the direction to check.

### ```Control:upate()```
Updates the state of the control. Call this on all of your controls each frame. Sorry you have to do this. :(
