local button = {}
button.__index = button

function button:update()
  self.downPrev = self.down
  self.down = false
  
  for k, v in pairs(self.detectors) do
    if v() then
      self.down = true
    end
  end
  
  self.pressed  = self.down and not self.downPrev
  self.released = self.downPrev and not self.down
end

local tactile = {}
tactile.__index = tactile

function tactile:addKeyboardButtonDetector(key)
  return function()
    return love.keyboard.isDown(key)
  end
end

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

function tactile:update()
  for k, v in pairs(self.buttons) do
    v:update()
  end
end

function tactile.new()
  local inputHandler = {
    buttons = {}
  }
  return setmetatable(inputHandler, tactile)
end

return tactile.new()