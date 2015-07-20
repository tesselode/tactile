local function removeByValue(t, value)
  for k, v in pairs(t) do
    if v == value then
      table.remove(t, k)
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
local tactile = {}
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
    return gamepad and gamepad:isGamepadDown(button) or false
  end
end

function tactile.mouseButton(button)
  return function()
    return love.mouse.isDown(button)
  end
end

function tactile.thresholdButton(axisDetector, threshold)
  return function()
    return axisDetector()
      and math.abs(axisDetector()) > math.abs(threshold)
      and (axisDetector() < 0) == (threshold < 0)
  end
end

--axis detectors
function tactile.binaryAxis(negative, positive)
  return function()
    if negative() and not positive() then
      return -1
    elseif positive() and not negative() then
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
