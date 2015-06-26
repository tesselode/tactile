local input = {}

input.joysticks = love.joystick.getJoysticks()
input.deadzone = 0.25

input.buttonDetectors = {}
input.buttons = {}

input.axisDetectors = {}
input.axes = {}

--general button detector class
function input:addButtonDetector (name)
  local detector = {}
  detector.prev = false
  detector.current = false

  function detector:update ()
    detector.prev = detector.current
  end

  self.buttonDetectors[name] = detector
  return(detector)
end

--detects if a keyboard key is down/pressed/released
function input:addKeyboardButtonDetector (name, key)
  assert(name, 'name is nil')
  assert(type(key) == 'string', 'key is not a KeyConstant')

  local detector = input:addButtonDetector(name)
  detector.key = key

  local parentUpdate = detector.update
  function detector:update ()
    parentUpdate(self)

    self.current = love.keyboard.isDown(self.key)
  end

  return detector
end

--detects if a mouse button is down/pressed/released
function input:addMouseButtonDetector (name, button)
  assert(name, 'name is nil')
  assert(type(button) == 'string', 'button is not a MouseConstant')

  local detector = input:addButtonDetector(name)
  detector.button = button

  local parentUpdate = detector.update
  function detector:update ()
    parentUpdate(self)

    self.current = love.mouse.isDown(self.button)
  end

  return detector
end

--detects if a gamepad button is down/pressed/released
function input:addGamepadButtonDetector (name, button, joystickNum)
  assert(name, 'name is nil')
  assert(type(button) == 'string', 'button is not a GamepadButton')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = input:addButtonDetector(name)
  detector.button = button
  detector.joystickNum = joystickNum
  detector.joysticks = self.joysticks

  local parentUpdate = detector.update
  function detector:update ()
    parentUpdate(self)

    if self.joysticks[self.joystickNum] then
      self.current = self.joysticks[self.joystickNum]:isGamepadDown(self.button)
    end
  end

  return detector
end

--detects if a joystick axis passes a certain threshold
function input:addAxisButtonDetector (name, axis, threshold, joystickNum)
  assert(name, 'name is nil')
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = input:addButtonDetector(name)
  detector.axis = axis
  detector.threshold = threshold
  detector.joysticks = self.joysticks
  detector.joystickNum = joystickNum

  local parentUpdate = detector.update
  function detector:update ()
    parentUpdate(self)

    if self.joysticks[self.joystickNum] then
      local axisValue = self.joysticks[self.joystickNum]:getGamepadAxis(axis)
      detector.current = (axisValue < 0) == (self.threshold < 0) and math.abs(axisValue) > math.abs(self.threshold)
    end
  end

  return detector
end

--removes a button detector
function input:removeButtonDetector (name)
  assert(name, 'name is nil')

  self.buttonDetectors[name] = nil
end

--holds detectors
function input:addButton (name, detectors)
  assert(name, 'name is nil')
  assert(type(detectors) == 'table', 'detectors is not a table')

  local button = {}
  button.detectors = {}
  for k, v in pairs(detectors) do
    table.insert(button.detectors, self.buttonDetectors[v])
  end

  button.prev = false
  button.current = false

  function button:update ()
    button.prev = button.current
    button.current = false

    for k, v in pairs(button.detectors) do
      --trigger the button if any of the detectors are triggered
      if v.current then
        button.current = true
      end
    end

    button.pressed = button.current and not button.prev
    button.released = button.prev and not button.current
  end

  self.buttons[name] = button
  return button
end

--removes a button
function input:removeButton (name)
  assert(name, 'name is nil')

  self.buttons[name] = nil
end

--general axis detector
function input:addAxisDetector (name)
  assert(name, 'name is nil')

  local axisDetector = {}
  axisDetector.value = 0
  axisDetector.parent = self

  function axisDetector:getValue ()
    if math.abs(self.value) > self.parent.deadzone then
      return self.value
    else
      return 0
    end
  end

  function axisDetector:update () end

  self.axisDetectors[name] = axisDetector
  return axisDetector
end

--joystick axis detector
function input:addAnalogAxisDetector (name, axis, joystickNum)
  assert(name, 'name is nil')
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local axisDetector = input:addAxisDetector(name)
  axisDetector.axis = axis
  axisDetector.joystickNum = joystickNum
  axisDetector.joysticks = self.joysticks

  function axisDetector:update ()
    if self.joysticks[self.joystickNum] then
      self.value = self.joysticks[self.joystickNum]:getGamepadAxis(self.axis)
    end
  end

  return axisDetector
end

--keyboard axis detector
function input:addBinaryAxisDetector (name, negative, positive)
  assert(name, 'name is nil')
  assert(negative, 'negative is nil')
  assert(positive, 'positive is nil')

  local axisDetector = input:addAxisDetector(name)
  axisDetector.negative = self.buttonDetectors[negative]
  axisDetector.positive = self.buttonDetectors[positive]

  function axisDetector:update ()
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
function input:removeAxisDetector (name)
  assert(name, 'name is nil')

  self.axisDetectors[name] = nil
end

--holds axis detectors
function input:addAxis (name, detectors)
  assert(name, 'name is nil')

  local axis = {}
  axis.detectors = {}
  for k, v in pairs(detectors) do
    table.insert(axis.detectors, self.axisDetectors[v])
  end

  axis.value = 0

  function axis:update ()
    axis.value = 0

    for i = 1, #self.detectors do
      if self.detectors[i]:getValue() ~= 0 then
        self.value = self.detectors[i]:getValue()
      end
    end
  end

  self.axes[name] = axis
  return axis
end

--removes an axis
function input:removeAxis (name)
  assert(name, 'name is nil')

  self.axes[name] = nil
end

function input:update ()
  --update button detectors
  for k, v in pairs(self.buttonDetectors) do
    v:update()
  end

  --update axis detectors
  for k, v in pairs(self.axisDetectors) do
    v:update()
  end

  --update buttons
  for k, v in pairs(self.buttons) do
    v:update()
  end

  --update axes
  for k, v in pairs(self.axes) do
    v:update()
  end
end

--access functions
function input:isDown (button)
  assert(button, 'button is nil')
  return self.buttons[button].current
end

function input:pressed (button)
  assert(button, 'button is nil')
  return self.buttons[button].pressed
end

function input:released (button)
  assert(button, 'button is nil')
  return self.buttons[button].released
end

function input:getAxis (axis)
  assert(axis, 'axis is nil')
  return self.axes[axis].value
end

--refreshes the joysticks list
function input:getJoysticks ()
  self.joysticks = love.joystick.getJoysticks()
end

return input
