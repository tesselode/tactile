Tactile
=======
Tactile is an input library for LÖVE to help you manage multiple input sources. It's flexible and straightforward and nice. :)

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
  keyboardLeft  = tactile.key('left')
  keyboardRight = tactile.key('right')
  keyboardX     = tactile.key('x')
  gamepadA      = tactile.gamepadButton('a', 1) --the second argument is controller number, in case you're wondering
  
  --axis detectors
  keyboardXAxis = tactile.binaryAxis(keyboardLeft, keyboardRight)
  gamepadXAxis  = tactile.analogStick('leftx', 1)
  
  --controls
  horizontal    = tactile.addAxis(keyboardXAxis, gamepadXAxis)
  shoot         = tactile.addButton(keyboardX, gamepadA)
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

`detector = tactile.key(key)`

Creates a button detector that is activated if a keyboard key is held down.

- `key` is the `KeyConstant` to check for.

`detector = tactile.gamepadButton(button, gamepadNum)`

Creates a button detector that is activated if a gamepad button is held down.

- `button` is the `GamepadButton` to check for.
- `gamepadNum` is the number of the gamepad that should be used.