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

  function detector:preUpdate ()
    detector.prev = detector.current
  end

  function detector:update () end

  function detector:postUpdate ()
    --detect pressed/released
    self.pressed = self.current and not self.prev
    self.released = self.prev and not self.current
  end

  self.buttonDetectors[name] = detector
  return(detector)
end

--detects if a keyboard key is down/pressed/released
function input:addKeyboardButtonDetector (name, key)
  local detector = input:addButtonDetector(name)
  detector.key = key

  function detector:update ()
    self.current = love.keyboard.isDown(self.key)
  end

  return detector
end

--detects if a mouse button is down/pressed/released
function input:addMouseButtonDetector (name, button)
  local detector = input:addButtonDetector(name)
  detector.button = button

  function detector:update ()
    self.current = love.mouse.isDown(self.button)
  end

  return detector
end

--detects if a gamepad button is down/pressed/released
function input:addGamepadButtonDetector (name, button, joystickNum)
  local detector = input:addButtonDetector(name)
  detector.button = button
  detector.joystickNum = joystickNum
  detector.joysticks = self.joysticks

  function detector:update ()
    self.current = self.joysticks[self.joystickNum]:isGamepadDown(self.button)
  end

  return detector
end

--detects if a joystick axis passes a certain threshold
function input:addAxisButtonDetector (name, axis, threshold, joystickNum)
  local detector = input:addButtonDetector(name)
  detector.axis = axis
  detector.threshold = threshold
  detector.joysticks = self.joysticks
  detector.joystickNum = joystickNum

  function detector:update ()
    local axisValue = self.joysticks[self.joystickNum]:getGamepadAxis(axis)
    detector.current = (axisValue < 0) == (self.threshold < 0) and math.abs(axisValue) > math.abs(self.threshold)
  end

  return detector
end

--holds detectors
function input:addButton (name, detectors)
  local button = {}
  button.detectors = {}
  for k, v in pairs(detectors) do
    table.insert(button.detectors, input.buttonDetectors[v])
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

--general axis detector
function input:addAxisDetector (name)
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
  local axisDetector = input:addAxisDetector(name)
  axisDetector.axis = axis
  axisDetector.joystickNum = joystickNum
  axisDetector.joysticks = self.joysticks

  function axisDetector:update ()
    self.value = self.joysticks[joystickNum]:getGamepadAxis(self.axis)
  end

  return axisDetector
end

--keyboard axis detector
function input:addBinaryAxisDetector (name, negative, positive)
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

--holds axis detectors
function input:addAxis (name, detectors)
  local axis = {}
  axis.detectors = {}
  for k, v in pairs(detectors) do
    table.insert(axis.detectors, input.axisDetectors[v])
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

function input:update ()
  --update detectors
  for k, v in pairs(self.buttonDetectors) do
    v:preUpdate()
    v:update()
    v:postUpdate()
  end

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
function input:isDown (button) return self.buttons[button].current end

function input:pressed (button) return self.buttons[button].pressed end

function input:released (button) return self.buttons[button].released end

function input:getAxis (axis) return self.axes[axis].value end

--refreshes the joysticks list
function input:getJoysticks ()
  self.joysticks = love.joystick.getJoysticks()
end

return input
