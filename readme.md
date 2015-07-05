Tactile
=======

Tactile is a straightforward and flexible input library for LÖVE.

If you want to use the library in your game, just grab tactile.lua and you're good to go! For an interactive example (that also acts as a test kind of sort of), clone the repo and run love in the project folder.

Overview
--------

Tactile has 5 different types of objects:

- **Button detectors** detect a single binary input (like keys and gamepad buttons)

- **Axis detectors** detect a single input that can vary from -1 to 1 (like analog sticks)

- **Buttons** are controls that are activated if any one of a set of button detectors detects an input.

- **Axes** are controls that are set from -1 to 1 based on a set of axis detectors.

- **Axis pairs** are controls that have an x and y value set by two axis detectors. They automatically limit the length of the vector to 1, restraining the control to a circle.

Example
-------
```lua
function love.load ()
  input = require 'tactile'

  --button detectors
  keyboardX     = input.addKeyboardButtonDetector('x')
  keyboardLeft  = input.addKeyboardButtonDetector('left')
  keyboardRight = input.addKeyboardButtonDetector('right')
  gamepadA      = input.addGamepadButtonDetector('a', 1)

  --axis detectors
  keyboardXAxis = input.addBinaryAxisDetector(keyboardLeft, keyboardRight)
  gamepadXAxis  = input.addAnalogAxisDetector('leftx', 1)

  --controls
  primary    = input.addButton(keyboardX, gamepadA)
  horizontal = input.addAxis(keyboardXAxis, gamepadXAxis)
end

function love.update (dt)
  input.update()

  --movement
  player.x += horizontal.value * player.speed * dt

  --shooting
  if primary.pressed then
    player:shoot()
  end
end
```

API
---
###Requiring the library

`input = require 'tactile'`

What do you know, it's just like every other library!

###Main module

`input.update()`

Checks for inputs every frame. Call this in love.update.

`input.getJoysticks()`

Refreshes the list of joysticks. Use this to check if a controller is plugged in or unplugged.

###Button detectors

`detector = input.addKeyboardButtonDetector(key)`

Adds a button detector that is triggered when a certain keyboard key is held down.

- `key` is the `KeyConstant` to check for.

`detector = input.addMouseButtonDetector(button)`

Adds a button detector that is triggered when a certain mouse button is held down.

- `button` is the `MouseConstant` to check for.

`detector = input.addGamepadButtonDetector(button, joystickNum)`

Adds a button detector that is triggered when a certain gamepad button is held down.

- `button` is the `GamepadButton` to check for.
- `joystickNum` is the joystick to check for input on.

`detector = input.addAxisButtonDetector(axis, threshold, joystickNum)`

Adds a button detector that is triggered when an axis on a gamepad passes a certain threshold. This is useful if you want an analog input to control a binary control, such as a menu navigation button. You can also use this to tack controller support onto a game that was only meant for keyboard, but in my heart, I know you can do better! :)

- `axis` is the `GamepadAxis` to check for.
- `threshold` is the value the axis has to reach for an input to be registered. If the threshold is positive, the value will have to be greater than the threshold. If the threshold is negative, the value will have to be smaller.
- `joystickNum` is the joystick to check for input on.

`input.removeButtonDetector(detector)`

Removes a button detector.

- `detector` is the button detector to remove.

### Buttons

`button = input.addButton(...)`

Adds a button.

- `...` is a list of button detectors that should activate this button.

`input.removeButton(button)`

Removes a button.

- `button` is the button to remove.

Buttons can be accessed using the following variables:

- `button.down` is true if the button is currently held down, false if not.
- `button.pressed` is true if the button was just pressed this frame, false if not.
- `button.released` is true if the button was just released this frame, false if not.

### Axis detectors

__Note:__ by default, all axis detectors have a deadzone of 0.25, meaning that any inputs with a magnitude of less than 0.25 will be ignored. You can change this setting by setting the variable input.deadzone.

`detector = input.addAnalogAxisDetector(axis, joystickNum)`

Adds an axis detector that reads an analog input from a controller.

- `axis` is the `GamepadAxis` to check for.
- `joystickNum` is the number of the joystick to check for.

`detector = input.addBinaryAxisDetector(negative, positive)`

Adds an axis detector that always has a value of -1, 0, or 1 based on the state of two button detectors. If the negative button detector is active, the value is -1. If the positive button detector is active, the value is 1. If both or neither are active, the value is 0. This is useful for allowing binary controls (like keyboard controls) to operate an axis (ie, if you designed your game for controller, but you also want to allow keyboard controls).

- `negative` is the button detector that will be assigned to the negative side.
- `positive` is the button detector that will be assigned to the positive side.

`input.removeAxisDetector(detector)`

Removes an axis detector.

- `detector` is the axis detector to remove.

### Axes

`axis = input.addAxis(...)`

Adds an axis.

- `...` is a list of axis detectors that the axis should use.
  - Note: axes check the list of axis detectors in order. The value of the axis will be set to the value of the first axis detector with a non-zero value. Because of this, if an axis uses an analog axis detector and a binary axis detector, it is recommended that you put the binary axis detector last in the list. Analog axis detectors almost never have a non-zero value due to analog sticks almost never being perfectly centered, and if they come last in the list, they'll always be registering an input and overriding the binary axis detector.

`input.removeAxis(axis)`

Removes a axis.

- `axis` is the axis to remove.

Axes can be accessed using the following variables:

- `axis.rawValue` is the current value of the axis (from -1 to 1).
- `axis.value` is the current value of the axis with deadzone taken into account.

### Axis Pairs

`axisPair = input.addAxisPair(...)`

Adds an axis pair that holds the values of two axes in the variables x and y. The vector (x, y) will be normalized if its length is more than 1. This is good for any game that allows the player to move in more than 4 directions, as it makes sure that the player will not move faster diagonally than in a cardinal direction.

- `...` is a list of detector pairs. A detector pair is a table where the first element is the horizontal axis detector and the second element is the vertical axis detector. Each detector pair represents an input method, like a keyboard or a gamepad.
  - Note: axis pairs have similar precedence rules to axes. The last detector pair in the list that has a non-zero value (including deadzone) will set the value of the axis pair. Remember: binary after analog!

`input.removeAxisPair(axisPair)`

Removes a axisPair.

- `axisPair` is the axis pair to remove.

Axis pairs can be accessed using the following variables:

- `axisPair.x` is the value of the horizontal axis (from -1 to 1).
- `axisPair.y` is the value of the vertical axis (from -1 to 1).
