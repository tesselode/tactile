Tactile
=======
Tactile is a flexible and straightforward input library for LÖVE to help you manage multiple input sources.

If you want to use the library in your game, just grab tactile.lua and you're good to go! For an interactive example (that also acts as a test kind of sort of), clone the repo and run love in the project folder.

Overview
--------
The two main objects in Tactile are **buttons** and **axes**. Buttons and axes are operated by a group of **detectors**, which are really just functions that return a value. Button detectors return true or false, and axis detectors return a number from -1 to 1. That's really abstract, so here's an example:

Example
-------
```lua
function love.load()
  tactile = require 'tactile'

  --button detectors
  keyboardLeft  = tactile.keys('left', 'a')
  keyboardRight = tactile.keys('right', 'd')
  keyboardShoot = tactile.keys('x', 'space')
  gamepadShoot  = tactile.gamepadButton(1, 'a', 'x') -- first argument is the gamepad ID

  --axis detectors
  keyboardMovement = tactile.binaryAxis(keyboardLeft, keyboardRight)
  gamepadMovement  = tactile.analogStick(1, 'leftx')

  --controls
  movement = tactile.newAxis(keyboardMovement, gamepadMovement)
  shoot    = tactile.newButton(keyboardShoot, gamepadShoot)
end

function love.update(dt)
  --you have to update buttons, sorry for the extra step :(
  shoot:update()

  --movement
  player.x = player.x + player.speed * horizontal:getValue() * dt

  --shooting
  if shoot:pressed() then
    player:shoot()
  end
end
```

API
---
###Requiring the library

`tactile = require 'tactile'`

What do you know, it's just like every other library!

###Button detectors

A button detector is simply a function that returns true or false. Each button detector represents a single source of binary input, like a keyboard key or gamepad button. For example, here is a completely valid button detector:

```lua
detector = function()
  return love.keyboard.isDown('left')
end
```

Tactile comes with a few functions that create some commonly used button detectors. They cover all the use cases I could think of, but you can always make a custom button detector if need be.

`detector = tactile.keys(...)`

Creates a button detector that is activated if any of the given keyboard keys are held down.

- `...` are the `KeyConstant`s to check for.

`detector = tactile.gamepadButton(gamepadNum, ...)`

Creates a button detector that is activated if any of the gamepad buttons are held down.

- `gamepadNum` is the number of the gamepad that should be checked.
- `...` are the `GamepadButton`s to check for.

`detector = tactile.mouseButton(...)`

Creates a button detector that is activated if any of the mouse buttons are held down.

- `...` are the `MouseConstant`s to check for.

`detector = tactile.thresholdButton(axisDetector, threshold)`

Creates a button detector that is activated if the value of an axis detector passes a certain threshold. This is useful if you want an analog input to control a binary control (for example, using an analog stick to navigate a menu). You can also use this to tack controller support onto a game that only has keyboard controls, but in my heart, I know you can do better. :)

- `axisDetector` is the axis detector to check.
- `threshold` is the threshold the axis detector has to pass for the button detector to be activated. This is sensitive to sign.

###Buttons

Buttons are containers for button detectors. If any of the button detectors are activated, the button will be activated. As well as reporting if they are held down, buttons also keep track of whether they were just pressed or released on the current frame.

`button = tactile.newButton(...)`

Creates a new button.

- `...` is a list of button detectors the button should use.

`button:update()`

Updates the button. Call this once per frame. Sorry you have to do this.

`button:addDetector(detector)`

Adds a button detector to the button.

- `detector` is the button detector to add.

`button:removeDetector(detector)`

Removes a button detector from the button.

- `detector` is the button detector to remove.

`button:isDown()`

Returns whether the button is currently being held down.

`button:pressed()`

Returns whether the button was just pressed this frame.

`button:released()`

Returns whether the button was just released this frame.

###Axis detectors

An axis detector is simply a function that returns a number from -1 to 1. Each axis detector represents a single analog control, like an analog stick on a gamepad. For example, here is a valid axis detector:

```lua
detector = function()
  return love.joystick.getJoysticks()[1]:getGamepadAxis('leftx')
end
```

Tactile comes with a few functions that create some commonly used axis detectors.

`detector = tactile.analogStick(gamepadNum, axis)`

Creates an axis detector that responds to an analog stick.

- `gamepadNum` is the number of the gamepad that should be checked.
- `axis` is the `GamepadAxis` to check for.

`detector = tactile.binaryAxis(negative, positive)`

Creates an axis detector that responds to two button detectors. If both or neither button detectors are activated, the returned value will be 0. If only the negative button detector is activated, the returned value will be -1. If only the positive button detector is activated, the returned value will be 1. This is useful for mapping binary controls to something that is normally operated by an axis, like keyboard controls for a game that is designed for the analog stick.

- `negative` is the button detector on the negative side.
- `positive` is the button detector on the positive side.

###Axes

Axes are containers for axis detectors. The value of the axis will be set to the last non-zero value from the list of axis detectors (accounting for deadzone). You should consider which input methods you want to take precedence to decide the order to add axis detectors in.

You can change the deadzone of the axis by setting `axis.deadzone`. Each axis has an individual deadzone setting. By default, it is 0.5.

`axis = tactile.newAxis(...)`

Creates a new axis.

- `...` is a list of axis detectors the axis should use.

`axis:addDetector(detector)`

Adds an axis detector to the axis.

- `detector` is the axis detector to add.

`axis:removeDetector(detector)`

Removes an axis detector from the axis.

- `detector` is the axis detector to remove.

`axis:getValue(deadzone)`

Returns the current value of the axis.

- `deadzone` is the deadzone to use. Leave this blank to use `axis.deadzone`.
