Tactile
=======

Tactile is a simple input library for LÖVE.

Overview
--------

Tactile is made up of four types of objects:

- **Button detectors** detect a single binary input (like keys and gamepad buttons)

- **Axis detectors** detect a single input that can vary from -1 to 1 (like analog sticks)

- **Buttons** are controls that are activated if any one of a set of button detectors detects an input.

- **Axes** are controls that are set from -1 to 1 based on a set of axis detectors.

API
---
###Requiring the library

`input = require 'input'`

What do you know, it's just like every other library!

###The basics

`input:update()`

Checks for inputs every frame. Call this in love.update.

`input:isDown(button)`

Returns true if a button is currently held down. Returns false if not.

- `button` is the name of the button to check.

`input:pressed(button)`

Returns true if a button was pressed this frame. Returns false if not.

- `button` is the name of the button to check.

`input:released(button)`

Returns true if a button was released this frame. Returns false if not.

- `button` is the name of the button to check.

`input:getAxis(axis)`

Returns the value of an axis (a float from -1 to 1).

- `axis` is the name of the axis to check.

`input:getJoysticks()`

Refreshes the list of joysticks. Use this to check if a controller is plugged in or unplugged.

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

Adds a button detector that is triggered when an axis on a gamepad passes a certain threshold. This is useful if you want an analog input to control a binary control, such as a menu navigation button. You can also use this to tack controller support onto a game that was only meant for keyboard, but in my heart, I know you can do better! :)

- `name` is the name of the button detector.
- `axis` is the `GamepadAxis` to check for.
- `threshold` is the value the axis has to reach for an input to be registered. If the threshold is positive, the value will have to be greater than the threshold. If the threshold is negative, the value will have to be smaller.
- `joystickNum` is the joystick to check for input on.

`input:removeButtonDetector(name)`

Removes a button detector.

- `name` is the name of the button detector.

### Buttons

`input:addButton(name, detectors)`

Adds a button.

- `name` is the name of the button.
- `detectors` is a table containing the names of all the button detectors that should activate this button.

`input:removeButton(name)`

Removes a button.

- `name` is the name of the button.

__Note:__ be careful when removing buttons! If another piece of code is still using them, the game will crash.

### Axis detectors

__Note:__ by default, all axis detectors have a deadzone of 0.25, meaning that any inputs with a magnitude of less than 0.25 will be ignored. You can change this setting by setting the variable input.deadzone.

`input:addAnalogAxisDetector (name, axis, joystickNum)`

Adds an axis detector that reads an analog input from a controller.

- `name` is the name of the axis detector.
- `axis` is the `GamepadAxis` to check for.
- `joystickNum` is the number of the joystick to check for.

`input:addBinaryAxisDetector (name, negative, positive)`

Adds an axis detector that always has a value of -1, 0, or 1 based on the state of two button detectors. If the negative button detector is active, the value is -1. If the positive button detector is active, the value is 1. If both or neither are active, the value is 0. This is useful for allowing binary controls (like keyboard controls) to operate an axis (ie, if you designed your game for controller, but you also want to allow keyboard controls).

- `name` is the name of the axis detector.
- `negative` is the name of a button detector. This will be assigned to the negative side.
- `positive` is the name of a button detector. This will be assigned to the positive side.

`input:removeAxisDetector(name)`

Removes an axis detector.

- `name` is the name of the axis detector.

### Axes

`input:addAxis(name, detectors)`

Adds an axis.

- `name` is the name of the axis.
- `detectors` is a table containing the names of all the axis detectors that the axis should use.
  - Note: the last axis detector in the list will take precedence! So if you want one control method to override the other, place it last in the list.

`input:removeAxis(name)`

Removes a axis.

- `name` is the name of the axis.

__Note:__ be careful when removing axes! If another piece of code is still using them, the game will crash.
