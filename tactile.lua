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

--axis class
local Axis = {}
Axis.__index = Axis

function Axis:update()
  self.value = 0
  
  --check whether any detectors have a value greater than the deadzone
  for k, v in pairs(self.detectors) do
    if v() and math.abs(v()) > self.deadzone then
      self.value = v()
    end
  end
end

--input handler class
local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler:addButton(...)
  local buttonInstance = {
    detectors = {...},
    down      = false,
    downPrev  = false,
    pressed   = false,
    released  = false
  }
  table.insert(self.buttons, buttonInstance)
  return setmetatable(buttonInstance, Button)
end

function InputHandler:addAxis(...)
  local axisInstance = {
    detectors = {...},
    deadzone  = self.deadzone,
    value     = 0
  }
  table.insert(self.axes, axisInstance)
  return setmetatable(axisInstance, Axis)
end

function InputHandler:update()
  for k, v in pairs(self.buttons) do
    v:update()
  end
  for k, v in pairs(self.axes) do
    v:update()
  end
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
      return false
    end
  end
end

function tactile.analogStick(axis, gamepadNum)
  return function()
    local gamepads = love.joystick.getJoysticks()
    if gamepads[gamepadNum] then
      return gamepads[gamepadNum]:getGamepadAxis(axis)
    else
      return false
    end
  end
end

--input handler constructor
function tactile.new()
  local inputHandlerInstance = {
    deadzone = 0.25,
    buttons  = {},
    axes     = {}
  }
  return setmetatable(inputHandlerInstance, InputHandler)
end

return tactile