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

--axis pair class
local AxisPair = {}
AxisPair.__index = AxisPair

function AxisPair:update()
  self.x = 0
  self.y = 0
  
  for i = 1, #self.detectors do
    local x, y
    
    --check if either axis detector is non-zero
    if math.abs(self.detectors[i][1]()) > self.deadzone then
      x = self.detectors[i][1]()
    end
    if math.abs(self.detectors[i][2]()) > self.deadzone then
      y = self.detectors[i][2]()
    end
    
    --if so, override both x and y
    if x or y then
      self.x = x or 0
      self.y = y or 0
    end
  end
  
  --restrict vector length to 1
  local len = math.sqrt(self.x ^ 2 + self.y ^ 2)
  if len > 1 then
    self.x = self.x / len
    self.y = self.y / len
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

function InputHandler:addAxisPair(...)
  local axisPairInstance = {
    detectors = {...},
    deadzone  = self.deadzone,
    x         = 0,
    y         = 0
  }
  table.insert(self.axisPairs, axisPairInstance)
  return setmetatable(axisPairInstance, AxisPair)
end

function InputHandler:update()
  for k, v in pairs(self.buttons) do
    v:update()
  end
  for k, v in pairs(self.axes) do
    v:update()
  end
  for k, v in pairs(self.axisPairs) do
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

--input handler constructor
function tactile.new()
  local inputHandlerInstance = {
    deadzone  = 0.25,
    buttons   = {},
    axes      = {},
    axisPairs = {}
  }
  return setmetatable(inputHandlerInstance, InputHandler)
end

return tactile