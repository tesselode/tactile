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
