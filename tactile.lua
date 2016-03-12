local tactile = {}

local function sign(x)
  return x < 0 and -1 or x > 0 and 1 or 0
end

local function verify(identity, argnum, value, expected, expectedstring)
  if type(value) ~= expected then
    error(string.format("%s: argument %d should be a %s, got %s", identity,
      argnum, expectedstring or expected, type(value)))
  end
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
      or p and 1
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
  for i, key in ipairs(keys) do
    verify('tactile.keys()', i, key, 'string', 'KeyConstant (string)')
  end
  return function()
    return love.keyboard.isDown(unpack(keys))
  end
end

function tactile.gamepadButtons(num, ...)
  local buttons = {...}
  for i, button in ipairs(buttons) do
    verify('tactile.gamepadButtons()', i, button, 'string',
      'GamepadButton (string)')
  end
  return function()
    return love.joystick.getJoysticks()[num]:isGamepadDown(unpack(buttons))
  end
end

function tactile.gamepadAxis(num, axis)
  verify('tactile.gamepadAxis()', 1, num, 'number')
  verify('tactile.gamepadAxis()', 2, axis, 'string', 'GamepadAxis (string)')
  return function()
    return love.joystick.getJoysticks()[num]:getGamepadAxis(axis)
  end
end

return tactile
