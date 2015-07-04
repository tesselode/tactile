local function removeByValue (t, value)
  for k, v in pairs(t) do
    if v == value then
      table.remove(t, k)
    end
  end
end

local tactile = {}

tactile.joysticks = love.joystick.getJoysticks()
tactile.deadzone = 0.25

tactile.buttonDetectors = {}
tactile.axisDetectors   = {}
tactile.buttons         = {}
tactile.axes            = {}
tactile.axisPairs       = {}

--general button detector class
function tactile.addButtonDetector()
  local detector = {}
  detector.down = false
  table.insert(tactile.buttonDetectors, detector)
  return detector
end

--detects if a keyboard key is down/pressed/released
function tactile.addKeyboardButtonDetector(key)
  assert(type(key) == 'string', 'key is not a KeyConstant')

  local detector = tactile.addButtonDetector()
  detector.key = key

  function detector:update()
    self.down = love.keyboard.isDown(self.key)
  end

  return detector
end

--detects if a mouse button is down/pressed/released
function tactile.addMouseButtonDetector(button)
  assert(type(button) == 'string', 'button is not a MouseConstant')

  local detector = tactile.addButtonDetector()
  detector.button = button

  function detector:update()
    self.down = love.mouse.isDown(self.button)
  end

  return detector
end

--detects if a gamepad button is down/pressed/released
function tactile.addGamepadButtonDetector(button, joystickNum)
  assert(type(button) == 'string', 'button is not a GamepadButton')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector()
  detector.button      = button
  detector.joystickNum = joystickNum

  function detector:update()
    if tactile.joysticks[self.joystickNum] then
      self.down = tactile.joysticks[self.joystickNum]:isGamepadDown(self.button)
    end
  end

  return detector
end

--detects if a joystick axis passes a certain threshold
function tactile.addAxisButtonDetector(axis, threshold, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector()
  detector.axis        = axis
  detector.threshold   = threshold
  detector.joystickNum = joystickNum

  function detector:update()
    if tactile.joysticks[self.joystickNum] then
      local axisValue = tactile.joysticks[self.joystickNum]:getGamepadAxis(axis)
      detector.down = (axisValue < 0) == (self.threshold < 0) and math.abs(axisValue) > math.abs(self.threshold)
    end
  end

  return detector
end

--removes a button detector
function tactile.removeButtonDetector(detector)
  assert(detector, 'detector is nil')
  removeByValue(tactile.buttonDetectors, detector)
end

--holds detectors
function tactile.addButton(detectors)
  assert(type(detectors) == 'table', 'detectors is not a table')

  local button = {}
  button.detectors = detectors

  button.downPrevious = false
  button.down         = false

  function button:update()
    button.downPrevious = button.down
    button.down = false

    for k, v in pairs(button.detectors) do
      --trigger the button if any of the detectors are triggered
      if v.down then
        button.down = true
      end
    end

    button.pressed  = button.down and not button.downPrevious
    button.released = button.downPrevious and not button.down
  end

  table.insert(tactile.buttons, button)
  return button
end

--removes a button
function tactile.removeButton(button)
  assert(button, 'button is nil')
  removeByValue(tactile.buttons, button)
end

--general axis detector
function tactile.addAxisDetector()
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

  table.insert(tactile.axisDetectors, axisDetector)
  return axisDetector
end

--joystick axis detector
function tactile.addAnalogAxisDetector(axis, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local axisDetector = tactile.addAxisDetector()
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
function tactile.addBinaryAxisDetector(negative, positive)
  assert(negative, 'negative is nil')
  assert(positive, 'positive is nil')

  local axisDetector = tactile.addAxisDetector()
  axisDetector.negative = negative
  axisDetector.positive = positive

  function axisDetector:update()
    if self.negative.down and self.positive.down then
      self.value = 0
    elseif self.negative.down then
      self.value = -1
    elseif self.positive.down then
      self.value = 1
    else
      self.value = 0
    end
  end

  return axisDetector
end

--removes an axis detector
function tactile.removeAxisDetector(detector)
  assert(detector, 'detector is nil')
  removeByValue(tactile.axisDetectors, detector)
end

--holds axis detectors
function tactile.addAxis(detectors)
  assert(type(detectors) == 'table', 'detectors is not a table')

  local axis = {}
  axis.detectors = detectors

  function axis:update()
    axis.value = 0

    --set the overall value to the last non-zero axis detector value
    for i = 1, #self.detectors do
      if self.detectors[i]:getValue() ~= 0 then
        self.value = self.detectors[i]:getValue()
      end
    end
  end

  table.insert(tactile.axes, axis)
  return axis
end

--removes an axis
function tactile.removeAxis(axis)
  assert(axis, 'axis is nil')
  removeByValue(tactile.axes, axis)
end

--holds two axes and calculates a vector (length limited to 1)
function tactile.addAxisPair(xAxis, yAxis)
  assert(xAxis, 'xAxis is nil')
  assert(yAxis, 'yAxis is nil')

  local axisPair = {}
  axisPair.xAxis = xAxis
  axisPair.yAxis = yAxis
  axisPair.x     = 0
  axisPair.y     = 0

  function axisPair:update()
    self.x = self.xAxis.value
    self.y = self.yAxis.value

    --normalize if length is more than 1
    local len = math.sqrt(self.x ^ 2 + self.y ^ 2)
    if len > 1 then
      self.x = self.x / len
      self.y = self.y / len
    end
  end

  table.insert(tactile.axisPairs, axisPair)
  return axisPair
end

function tactile.removeAxisPair(axisPair)
  assert(axisPair, 'axisPair is nil')
  removeByValue(tactile.axisPairs, axisPair)
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

  --update axis pairs
  for k, v in pairs(tactile.axisPairs) do
    v:update()
  end
end

--refreshes the joysticks list
function tactile.getJoysticks()
  tactile.joysticks = love.joystick.getJoysticks()
end

return tactile
