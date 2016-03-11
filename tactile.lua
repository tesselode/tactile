local tactile = {}

local function any(t, f)
  for i = 1, #t do
    if f(t[i]) then
      return true
    end
  end
  return false
end

local function sign(x)
  return x < 0 and -1 or x > 0 and 1 or 0
end

local Control = {}

function Control:addAxis(f)
  table.insert(self._detectors, f)
  return self
end

function Control:addButton(f)
  table.insert(self._detectors, function()
    return f() and 1 or 0
  end)
  return self
end

function Control:addButtonPair(negative, positive)
  table.insert(self._detectors, function()
    local n, p = negative(), positive()
    return n and p and 0
    or n and -1
    or n and 1
    or 0
  end)
  return self
end

function Control:getValue()
  for i = #self._detectors, 1, -1 do
    local value = self._detectors[i]()
    if math.abs(value) > self.deadzone then
      return value
    end
  end
  return 0
end

function Control:isDown(dir)
  local value = self:getValue()
  return dir and sign(value) == sign(dir) or value ~= 0
end

function Control:pressed(dir)
  return dir and sign(self._currentValue) == sign(dir)
  or not (self._currentValue == 0 or self._previousValue ~= 0)
end

function Control:released(dir)
  return dir and sign(self._previousValue) == sign(dir)
  or not (self._previousValue == 0 or self._currentValue ~= 0)
end

function Control:update()
  self._previousValue = self._currentValue
  self._currentValue = self:getValue()
end

function tactile.newControl()
  local control = {
    deadzone = .5,
    _detectors = {},
    _currentValue = 0,
    _previousValue = 0,
  }

  setmetatable(control, {__index = Control})
  return control
end

function tactile.keys(...)
  local keys = {...}
  return function()
    return love.keyboard.isDown(unpack(keys))
  end
end

function tactile.gamepadButtons(num, ...)
  local buttons = {...}
  return function()
    return love.joystick.getJoysticks()[num]:isGamepadDown(unpack(buttons))
  end
end

function tactile.gamepadAxis(num, axis)
  return function()
    return love.joystick.getJoysticks()[num]:getGamepadAxis(axis)
  end
end

return tactile
