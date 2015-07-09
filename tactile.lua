--button class
local button = {}
button.__index = button

function button:update()
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
local axis = {}
axis.__index = axis

function axis:update()
  self.value = 0
  
  for k, v in pairs(self.detectors) do
    if v() and math.abs(v()) > self.deadzone then
      self.value = v()
    end
  end
end

--main module
local tactile = {}
tactile.__index = tactile

--button detectors
function tactile:addKeyboardButtonDetector(key)
  return function()
    return love.keyboard.isDown(key)
  end
end

--axis detectors
function tactile:addBinaryAxisDetector(negative, positive)
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

function tactile:addGamepadAxisDetector(axis, gamepadNum)
  return function()
    if self.gamepads[gamepadNum] then
      return self.gamepads[gamepadNum]:getGamepadAxis(axis)
    else
      return false
    end
  end
end

--button constructor
function tactile:addButton(...)
  local buttonInstance = {
    detectors = {...},
    down      = false,
    downPrev  = false,
    pressed   = false,
    released  = false
  }
  table.insert(self.buttons, buttonInstance)
  return setmetatable(buttonInstance, button)
end

--axis constructor
function tactile:addAxis(...)
  local axisInstance = {
    detectors = {...},
    deadzone  = self.deadzone,
    value     = 0
  }
  table.insert(self.axes, axisInstance)
  return setmetatable(axisInstance, axis)
end

function tactile:update()
  for k, v in pairs(self.buttons) do
    v:update()
  end
  for k, v in pairs(self.axes) do
    v:update()
  end
end

--gives you a new input handler
function tactile.new()
  local inputHandler = {
    gamepads = love.joystick.getJoysticks(),
    deadzone = 0.25,
    buttons  = {},
    axes     = {}
  }
  return setmetatable(inputHandler, tactile)
end

--return a default input handler
return tactile.new()