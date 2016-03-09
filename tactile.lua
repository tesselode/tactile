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
  if x < 0 then
    return -1
  else
    return 0
  end
end

local Control = {}

function Control:addAxisDetector(f)
  table.insert(self._detectors, f)
end

function Control:addPositiveButtonDetector(f)
  table.insert(self._detectors, function()
    if f() then
      return 1
    else
      return 0
    end
  end)
end

function Control:addButtonPair(negative, positive)
  table.insert(self._detectors, function()
    local n, p = negative(), positive()
    if n and p then
      return 0
    elseif n then
      return -1
    elseif p then
      return 1
    else
      return 0
    end
  end)
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
  if self:getValue() == 0 then
    return false
  end
  if dir then
    if sign(self:getValue()) ~= sign(dir) then
      return false
    end
  end
  return true
end

function Control:pressed(dir)
  if self._currentValue == 0 or self._previousValue ~= 0 then
    return false
  end
  if dir then
    if sign(self._currentValue) ~= sign(dir) then
      return false
    end
  end
  return true
end

function Control:released(dir)
  if self._previousValue == 0 or self._currentValue ~= 0 then
    return false
  end
  if dir then
    if sign(self._previousValue) ~= sign(dir) then
      return false
    end
  end
  return true
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
