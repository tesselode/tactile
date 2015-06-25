Tactile
=======

Tactile is a simple input library for LÖVE. Tactile is made up of four types of objects:

- **Button detectors** take an input and return a binary value

- **Axis detectors** take an input and return a value from -1 to 1

- **Buttons** are containers for button detectors. If any of the detectors are true, the whole button is true.

- **Axes** are containers for axis detectors. They default to zero, and if any of the detectors have a non-zero value, the axis takes on that value. (The axis detector added last takes precedence.)

API
---
###Requiring the library

`local input = require 'input'`

What do you know, it's just like every other library!

###Button detectors

`input:addKeyboardButtonDetector(name, key)`

Adds a button detector that is triggered when a certain keyboard key is held down.

- `name` is the name of the button detector.
- `key` is the `KeyConstant` to check for.

`input:addMouseButtonDetector(name, button)`

Adds a button detector that is triggered when a certain mouse button is held down.

- `name` is the name of the button detector.
- `button` is the `MouseConstant` to check for.

`input:addGamepadButtonDetector (name, button, joystickNum)`

Adds a button detector that is triggered when a certain gamepad button is held down.

- `name` is the name of the button detector.
- `button` is the `GamepadButton` to check for.
- `joystickNum` is the joystick to check for input on.

`input:addAxisButtonDetector (name, axis, threshold, joystickNum)`

Adds a button detector that is triggered when an axis on a gamepad passes a certain threshold. This is useful if you want an analog input to control a binary control, such as menu controls. You can also use this to tack controller support onto a game that was only meant for keyboard, but in my heart, I know you can do better! :)

- `name` is the name of the button detector.
- `button` is the `GamepadButton` to check for.
- `threshold` is the value the axis has to reach for an input to be registered. This value takes direction into account.
- `joystickNum` is the joystick to check for input on.

### To be continued...
