local tactile = {
  _VERSION     = 'Tactile v1.0.0',
  _DESCRIPTION = 'A simple and straightfoward input library for LOVE.',
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

--button class
local Button = {}
Button.__index = Button

function Button:update()
  self.downPrev = self.down
  self.down = false

  --check whether any detectors are down
  for _, detector in pairs(self.detectors) do
    if detector() then
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

function Axis:getValue()
  self.value = 0

  --check whether any detectors have a value greater than the deadzone
  for _, detector in pairs(self.detectors) do
    local value = detector()
    if math.abs(value) > tactile.deadzone then
      self.value = value
    end
  end

  return self.value
end

function Axis:addDetector(detector)
  table.insert(self.detectors, detector)
end

function Axis:removeDetector(detector)
  removeByValue(self.detectors, detector)
end

--main module
tactile.__index = tactile
tactile.deadzone = .25
tactile.gamepads = love.joystick.getJoysticks()

function tactile.rescan()
  tactile.gamepads = love.joystick.getJoysticks()
end

--button detectors
function tactile.key(key)
  return function()
    return love.keyboard.isDown(key)
  end
end

function tactile.gamepadButton(button, gamepadNum)
  return function()
    local gamepad = tactile.gamepads[gamepadNum]
    return gamepad and gamepad:isGamepadDown(button)
  end
end

function tactile.mouseButton(button)
  return function()
    return love.mouse.isDown(button)
  end
end

function tactile.thresholdButton(axisDetector, threshold)
  return function()
    local value = axisDetector()
    return value and math.abs(value) > math.abs(threshold) and (value < 0) == (threshold < 0)
  end
end

--axis detectors
function tactile.binaryAxis(negative, positive)
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

function tactile.analogStick(axis, gamepadNum)
  return function()
    local gamepad = tactile.gamepads[gamepadNum]
    return gamepad and gamepad:getGamepadAxis(axis) or 0
  end
end

--button constructor
function tactile.newButton(...)
  local buttonInstance = {
    detectors = {...},
    down      = false,
    downPrev  = false
  }
  return setmetatable(buttonInstance, Button)
end

--axis constructor
function tactile.newAxis(...)
  local axisInstance = {
    detectors = {...}
  }
  return setmetatable(axisInstance, Axis)
end

return tactile
