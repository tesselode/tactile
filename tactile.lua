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
  for k, v in pairs(self.detectors) do
    if v() then
      self.down = true
    end
  end
  
  --pressed and released states
  self.pressed  = self.down and not self.downPrev
  self.released = self.downPrev and not self.down
end

function Button:addDetector(detector)
  table.insert(self.detectors, detector)
end

function Button:removeDetector(detector)
  removeByValue(self.detectors, detector)
end

function Button:isDown() return self.down end
function Button:pressed() return self.pressed end
function Button:released() return self.released end

--axis class
local Axis = {}
Axis.__index = Axis

function Axis:getAxis()
  self.value = 0
  
  --check whether any detectors have a value greater than the deadzone
  for k, v in pairs(self.detectors) do
    if math.abs(v()) > self.deadzone then
      self.value = v()
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
local tactile = {}
tactile.__index = tactile

--button detectors
function tactile.key(key)
  return function()
    return love.keyboard.isDown(key)
  end
end

function tactile.gamepadButton(button, gamepadNum)
  return function()
    local gamepads = love.joystick.getJoysticks()
    if gamepads[gamepadNum] then
      return gamepads[gamepadNum]:isGamepadDown(button)
    else
      return false
    end
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
    local gamepads = love.joystick.getJoysticks()
    if gamepads[gamepadNum] then
      return gamepads[gamepadNum]:getGamepadAxis(axis)
    else
      return 0
    end
  end
end

--button constructor
function tactile.addButton(...)
  local buttonInstance = {
    detectors = {...},
    down      = false,
    downPrev  = false,
    pressed   = false,
    released  = false
  }
  return setmetatable(buttonInstance, Button)
end

--axis constructor
function tactile.addAxis(...)
  local axisInstance = {
    detectors = {...},
    deadzone  = self.deadzone,
    value     = 0
  }
  return setmetatable(axisInstance, Axis)
end

return tactile