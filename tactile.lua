local tactile = {}

tactile.joysticks = love.joystick.getJoysticks()
tactile.deadzone = 0.25

tactile.buttonDetectors = {}
tactile.buttons = {}
tactile.axisDetectors = {}
tactile.axes = {}

--general button detector class
function tactile.addButtonDetector(name)
  local detector = {}
  detector.current = false
  tactile.buttonDetectors[name] = detector
  return(detector)
end

--detects if a keyboard key is down/pressed/released
function tactile.addKeyboardButtonDetector(name, key)
  assert(name, 'name is nil')
  assert(type(key) == 'string', 'key is not a KeyConstant')

  local detector = tactile.addButtonDetector(name)
  detector.key = key

  function detector:update()
    self.current = love.keyboard.isDown(self.key)
  end

  return detector
end

--detects if a mouse button is down/pressed/released
function tactile.addMouseButtonDetector(name, button)
  assert(name, 'name is nil')
  assert(type(button) == 'string', 'button is not a MouseConstant')

  local detector = tactile.addButtonDetector(name)
  detector.button = button

  function detector:update()
    self.current = love.mouse.isDown(self.button)
  end

  return detector
end

--detects if a gamepad button is down/pressed/released
function tactile.addGamepadButtonDetector(name, button, joystickNum)
  assert(name, 'name is nil')
  assert(type(button) == 'string', 'button is not a GamepadButton')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector(name)
  detector.button      = button
  detector.joystickNum = joystickNum

  function detector:update()
    if tactile.joysticks[self.joystickNum] then
      self.current = tactile.joysticks[self.joystickNum]:isGamepadDown(self.button)
    end
  end

  return detector
end

--detects if a joystick axis passes a certain threshold
function tactile.addAxisButtonDetector(name, axis, threshold, joystickNum)
  assert(name, 'name is nil')
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector(name)
  detector.axis        = axis
  detector.threshold   = threshold
  detector.joystickNum = joystickNum

  function detector:update()
    if tactile.joysticks[self.joystickNum] then
      local axisValue = tactile.joysticks[self.joystickNum]:getGamepadAxis(axis)
      detector.current = (axisValue < 0) == (self.threshold < 0) and math.abs(axisValue) > math.abs(self.threshold)
    end
  end

  return detector
end

--removes a button detector
function tactile.removeButtonDetector(name)
  assert(name, 'name is nil')

  tactile.buttonDetectors[name] = nil
end

--holds detectors
function tactile.addButton(name, detectors)
  assert(name, 'name is nil')
  assert(type(detectors) == 'table', 'detectors is not a table')

  local button = {}
  button.detectors = {}
  for k, v in pairs(detectors) do
    table.insert(button.detectors, tactile.buttonDetectors[v])
  end

  button.prev    = false
  button.current = false

  function button:update()
    button.prev = button.current
    button.current = false

    for k, v in pairs(button.detectors) do
      --trigger the button if any of the detectors are triggered
      if v.current then
        button.current = true
      end
    end

    button.pressed  = button.current and not button.prev
    button.released = button.prev and not button.current
  end

  tactile.buttons[name] = button
  return button
end

--removes a button
function tactile.removeButton(name)
  assert(name, 'name is nil')

  tactile.buttons[name] = nil
end

--general axis detector
function tactile.addAxisDetector(name)
  assert(name, 'name is nil')

  local axisDetector = {}
  axisDetector.value = 0

  function axisDetector:getValue()
    if math.abs(self.value) > tactile.deadzone then
      return self.value
    else
      return 0
    end
  end

  function axisDetector:update() end

  tactile.axisDetectors[name] = axisDetector
  return axisDetector
end

--joystick axis detector
function tactile.addAnalogAxisDetector(name, axis, joystickNum)
  assert(name, 'name is nil')
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local axisDetector = tactile.addAxisDetector(name)
  axisDetector.axis        = axis
  axisDetector.joystickNum = joystickNum

  function axisDetector:update()
    if tactile.joysticks[self.joystickNum] then
      self.value = tactile.joysticks[self.joystickNum]:getGamepadAxis(self.axis)
    end
  end

  return axisDetector
end

--keyboard axis detector
function tactile.addBinaryAxisDetector(name, negative, positive)
  assert(name, 'name is nil')
  assert(negative, 'negative is nil')
  assert(positive, 'positive is nil')

  local axisDetector = tactile.addAxisDetector(name)
  axisDetector.negative = tactile.buttonDetectors[negative]
  axisDetector.positive = tactile.buttonDetectors[positive]

  function axisDetector:update()
    if self.negative.current and self.positive.current then
      self.value = 0
    elseif self.negative.current then
      self.value = -1
    elseif self.positive.current then
      self.value = 1
    else
      self.value = 0
    end
  end

  return axisDetector
end

--removes an axis detector
function tactile.removeAxisDetector(name)
  assert(name, 'name is nil')

  tactile.axisDetectors[name] = nil
end

--holds axis detectors
function tactile.addAxis(name, detectors)
  assert(name, 'name is nil')

  local axis = {}
  axis.detectors = {}
  for k, v in pairs(detectors) do
    table.insert(axis.detectors, tactile.axisDetectors[v])
  end

  function axis:update()
    axis.value = 0

    for i = 1, #self.detectors do
      if self.detectors[i]:getValue() ~= 0 then
        self.value = self.detectors[i]:getValue()
      end
    end
  end

  tactile.axes[name] = axis
  return axis
end

--removes an axis
function tactile.removeAxis(name)
  assert(name, 'name is nil')

  tactile.axes[name] = nil
end

function tactile.update()
  --update button detectors
  for k, v in pairs(tactile.buttonDetectors) do
    v:update()
  end

  --update axis detectors
  for k, v in pairs(tactile.axisDetectors) do
    v:update()
  end

  --update buttons
  for k, v in pairs(tactile.buttons) do
    v:update()
  end

  --update axes
  for k, v in pairs(tactile.axes) do
    v:update()
  end
end

--access functions
function tactile.isDown(button)
  assert(button, 'button is nil')
  return tactile.buttons[button].current
end

function tactile.pressed(button)
  assert(button, 'button is nil')
  return tactile.buttons[button].pressed
end

function tactile.released(button)
  assert(button, 'button is nil')
  return tactile.buttons[button].released
end

function tactile.getAxis(axis)
  assert(axis, 'axis is nil')
  return tactile.axes[axis].value
end

--refreshes the joysticks list
function tactile.getJoysticks()
  tactile.joysticks = love.joystick.getJoysticks()
end

return tactile
