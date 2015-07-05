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
  table.insert(tactile.buttonDetectors, detector)
  return detector
end

--detects if a keyboard key is down/pressed/released
function tactile.addKeyboardButtonDetector(button)
  assert(type(button) == 'string', 'key is not a KeyConstant')

  local detector = tactile.addButtonDetector()
  
  function detector.isDown()
    return love.keyboard.isDown(button)
  end

  return detector
end

--detects if a mouse button is down/pressed/released
function tactile.addMouseButtonDetector(button)
  assert(type(button) == 'string', 'button is not a MouseConstant')

  local detector = tactile.addButtonDetector()
  
  function detector.isDown()
    return love.mouse.isDown(button)
  end

  return detector
end

--detects if a gamepad button is down/pressed/released
function tactile.addGamepadButtonDetector(button, joystickNum)
  assert(type(button) == 'string', 'button is not a GamepadButton')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector()
  
  function detector.isDown()
    local joystick = tactile.joysticks[joystickNum]
    return joystick and joystick:isGamepadDown(button)
  end

  return detector
end

--detects if a joystick axis passes a certain threshold
function tactile.addAxisButtonDetector(axis, threshold, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector()
  
  function detector.isDown()
    local joystick = tactile.joysticks[joystickNum]
    if joystick then
      local axisValue = joystick:getGamepadAxis(axis)
      return (axisValue < 0) == (threshold < 0) and
          math.abs(axisValue) > math.abs(threshold)
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
  local downPrevious, down

  function button.update()
    downPrevious = down
    down = false

    for k, detector in pairs(detectors) do
      --trigger the button if any of the detectors are triggered
      if detector.isDown() then
        down = true
      end
    end

  end
  
  function button.isDown()
    return down
  end
  
  function button.isPressed()
    return down and not downPrevious
  end

  function button.isReleased()
    return downPrevious and not down
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
  local detector = {}

  table.insert(tactile.axisDetectors, detector)
  return detector
end

--get an axis value, adjusted for deadzone
local function getAxisValue (value)
  return math.abs(value) > tactile.deadzone and value or 0
end

--joystick axis detector
function tactile.addAnalogAxisDetector(axis, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addAxisDetector()
  
  function detector.getValue()
    local joystick = tactile.joysticks[joystickNum]
    return joystick and getAxisValue(joystick:getGamepadAxis(axis)) or 0
  end

  return detector
end

--keyboard axis detector
function tactile.addBinaryAxisDetector(negative, positive)
  assert(negative, 'negative is nil')
  assert(positive, 'positive is nil')

  local detector = tactile.addAxisDetector()
  
  function detector.getValue()
    local negativeIsDown, positiveIsDown = negative.isDown(), positive.isDown()
    
    if negativeIsDown and positiveIsDown then
      return 0
    end
    if negativeIsDown then
      return -1
    end
    if positiveIsDown then
      return 1
    end
    return 0
  end

  return detector
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
  local value = 0

  function axis.update()
    --set the overall value to the last non-zero axis detector value
    for i = 1, #detectors do
      local detectorValue = detectors[i].getValue()
      if detectorValue ~= 0 then
        value = detectorValue
      end
    end
  end
  
  function axis.getValue()
    return value
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

  --update buttons
  for k, v in pairs(tactile.buttons) do
    v.update()
  end

  --update axes
  for k, v in pairs(tactile.axes) do
    v.update()
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
