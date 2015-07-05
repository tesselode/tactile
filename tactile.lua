local function removeByValue (t, value)
  for k, v in pairs(t) do
    if v == value then
      table.remove(t, k)
    end
  end
end

local tactile = {}

tactile.joysticks = love.joystick.getJoysticks()
tactile.deadzone         = 0.25
tactile.separateDeadzone = true

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
function tactile.addButton(...)
  local button = {}
  button.detectors = {...}

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
function tactile.addAxis(...)
  local axis = {}
  axis.detectors = {...}
  axis.rawValue  = 0
  axis.value     = 0

  function axis:update()
    axis.rawValue = 0

    --set the raw value to the last non-zero axis detector value
    for i = 1, #self.detectors do
      if self.detectors[i].value ~= 0 then
        self.rawValue = self.detectors[i].value
      end
    end

    --apply deadzone to get the final value
    if math.abs(self.rawValue) > tactile.deadzone then
      self.value = self.rawValue
    else
      self.value = 0
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
function tactile.addAxisPair(...)
  local axisPair = {}
  axisPair.detectorPairs = {...}
  axisPair.x     = 0
  axisPair.y     = 0

  function axisPair:update()
    self.x = 0
    self.y = 0

    --iterate through detector pairs
    for i = 1, #self.detectorPairs do
      local pair = self.detectorPairs[i]
      local x    = pair[1].value
      local y    = pair[2].value

      --set self values to detector pair values
      if tactile.separateDeadzone then
        --using separate axis deadzone calculation
        local appliedX, appliedY
        if math.abs(x) > tactile.deadzone then
          appliedX = x
        else
          appliedX = 0
        end
        if math.abs(y) > tactile.deadzone then
          appliedY = y
        else
          appliedY = 0
        end
        if appliedX ~= 0 or appliedY ~= 0 then
          self.x = appliedX
          self.y = appliedY
        end
      else
        --using vector length deadzone calculation
        local len = math.sqrt(x^2 + y^2)
        if len > tactile.deadzone then
          self.x = x
          self.y = y
        end
      end
    end

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
