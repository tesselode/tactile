local tactile = {
  _VERSION     = 'Tactile v1.3',
  _DESCRIPTION = 'A simple and straightfoward input library for LÖVE.',
  _URL         = 'https://github.com/tesselode/tactile',
  _LICENSE     = [[
    The MIT License (MIT)

    Copyright (c) 2015 Andrew Minnich

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]]
}

local function removeByValue(t, value)
  for i = #t, 1, -1 do
    if t[i] == value then
      table.remove(t, i)
      break
    end
  end
end

local function verify(identity, argnum, arg, argtype, expected)
  if type(arg) ~= argtype then
    error(("%s: argument %d should be a %s (got %s)"):format(identity, argnum, expected or argtype, type(arg)), 3)
  end
end

--button class
local Button = {}
Button.__index = Button

function Button:update()
  self.downPrev = self.down
  self.down = false

  --check whether any detectors are down
  for i = 1, #self.detectors do
    if self.detectors[i]() then
      self.down = true
      break
    end
  end
end

function Button:addDetector(detector)
  table.insert(self.detectors, detector)
end

function Button:removeDetector(detector)
  removeByValue(self.detectors, detector)
end

function Button:isDown() return self.down end
function Button:pressed() return self.down and not self.downPrev end
function Button:released() return self.downPrev and not self.down end

--axis class
local Axis = {}
Axis.__index = Axis

function Axis:getValue(deadzone)
  deadzone = deadzone or self.deadzone
  self.value = 0

  --check whether any detectors have a value greater than the deadzone
  for i = #self.detectors, 1, -1 do
    local value = self.detectors[i]()
    if math.abs(value) > deadzone then
      self.value = value
      return value
    end
  end
end

function Axis:addDetector(detector)
  table.insert(self.detectors, detector)
end

function Axis:removeDetector(detector)
  removeByValue(self.detectors, detector)
end

--main module
tactile.__index = tactile

--button detectors
function tactile.keys(...)
  for i = 1, select('#', ...) do
    verify('tactile.keys', i, select(i, ...), 'string', 'KeyConstant (string)')
  end

  local keys = {...}
  return function()
    return love.keyboard.isDown(unpack(keys))
  end
end

function tactile.scancodes(...)
  for i = 1, select('#', ...) do
    verify('tactile.scancodes', i, select(i, ...), 'string', 'Scancode (string)')
  end

  local keys = {...}
  return function()
    return love.keyboard.isScancodeDown(unpack(keys))
  end
end

function tactile.gamepadButtons(gamepadNum, ...)
  verify('tactile.gamepadButtons', 1, gamepadNum, 'number')

  for i = 1, select('#', ...) do
    verify('tactile.gamepadButtons', i + 1, select(i, ...), 'string', 'GamepadButton (string)')
  end

  local buttons = {...}
  return function()
    local gamepad = love.joystick.getJoysticks()[gamepadNum]
    return gamepad and gamepad:isGamepadDown(unpack(buttons))
  end
end

function tactile.mouseButtons(...)
  local major, minor, revision = love.getVersion()
  local t = "string"

  -- LOVE 0.10+ switched from strings (l, r, m) to numbers (1, 2, 3)
  if minor > 9 then
    t = "number"
  end

  for i = 1, select('#', ...) do
    verify('tactile.mouseButtons', i, select(i, ...), t, 'MouseButton ('..t..')')
  end

  local buttons = {...}
  return function()
    return love.mouse.isDown(unpack(buttons))
  end
end

function tactile.thresholdButton(axisDetector, threshold)
  verify('tactile.thresholdButton', 1, axisDetector, 'function', 'Axis Detector (function)')
  verify('tactile.thresholdButton', 2, threshold, 'number', 'a number between -1 and 1')

  return function()
    local value = axisDetector()
    return value and math.abs(value) > math.abs(threshold) and (value < 0) == (threshold < 0)
  end
end

--axis detectors
function tactile.binaryAxis(negative, positive)
  verify('tactile.binaryAxis', 1, negative, 'function', 'Axis Detector (function)')
  verify('tactile.binaryAxis', 2, positive, 'function', 'Axis Detector (function)')

  return function()
    local negativeValue, positiveValue = negative(), positive()
    if negativeValue and not positiveValue then
      return -1
    elseif positiveValue and not negativeValue then
      return 1
    else
      return 0
    end
  end
end

function tactile.booleanAxis(buttonDetector, whenTrue, whenFalse)
  verify('tactile.booleanAxis', 1, buttonDetector, 'function', 'Button Detector (function)')
  verify('tactile.booleanAxis', 2, whenTrue, 'number')
  verify('tactile.booleanAxis', 3, whenFalse, 'number')
  return function()
    return buttonDetector() and whenTrue or whenFalse
  end
end

function tactile.analogStick(gamepadNum, axis)
  verify('tactile.analogStick', 1, gamepadNum, 'number')
  verify('tactile.analogStick', 2, axis, 'string', 'GamepadAxis (string)')

  return function()
    local gamepad = love.joystick.getJoysticks()[gamepadNum]
    return gamepad and gamepad:getGamepadAxis(axis) or 0
  end
end

--button constructor
function tactile.newButton(...)
  for i = 1, select('#', ...) do
    verify('tactile.newButton', i, select(i, ...), 'function', 'Detector (function)')
  end

  local buttonInstance = {
    detectors = {...},
    down      = false,
    downPrev  = false
  }
  return setmetatable(buttonInstance, Button)
end

--axis constructor
function tactile.newAxis(...)
  for i = 1, select('#', ...) do
    verify('tactile.newAxis', i, select(i, ...), 'function', 'Detector (function)')
  end

  local axisInstance = {
    detectors = {...},
    deadzone  = 0.5
  }
  return setmetatable(axisInstance, Axis)
end

return tactile
