local tactile = {}

local tactileJoysticks = love.joystick.getJoysticks()
local tactileDeadzone = 0.25
local tactileControls = {}

--set deadzone value for all axis detectors
function tactile.setDeadzone(value)
  assert(type(value) == 'number', 'deadzone is not a number')
  tactileDeadzone = value
end

--detects if a keyboard key is down
function tactile.addKeyboardButtonDetector(button)
  assert(type(button) == 'string', 'key is not a KeyConstant')

  local detector = {}
  
  function detector.isDown()
    return love.keyboard.isDown(button)
  end

  return detector
end

--detects if a mouse button is down
function tactile.addMouseButtonDetector(button)
  assert(type(button) == 'string', 'button is not a MouseConstant')

  local detector = {}
  
  function detector.isDown()
    return love.mouse.isDown(button)
  end

  return detector
end

--detects if a gamepad button is down/pressed/released
function tactile.addGamepadButtonDetector(button, joystickNum)
  assert(type(button) == 'string', 'button is not a GamepadButton')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = {}
  
  function detector.isDown()
    local joystick = tactileJoysticks[joystickNum]
    return joystick and joystick:isGamepadDown(button)
  end

  return detector
end

--detects if a joystick axis passes a certain threshold
function tactile.addAxisButtonDetector(axis, threshold, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = {}
  
  function detector.isDown()
    local joystick = tactileJoysticks[joystickNum]
    if joystick then
      local axisValue = joystick:getGamepadAxis(axis)
      return (axisValue < 0) == (threshold < 0) and
          math.abs(axisValue) > math.abs(threshold)
    end
  end

  return detector
end

--holds detectors
function tactile.addButton(...)
  local detectors = { ... }
  local button = {}
  local downPrevious, down

  function button.update()
    downPrevious = down
    down = false

    for k, detector in ipairs(detectors) do
      --trigger the button if any of the detectors are triggered
      if detector.isDown() then
        down = true
        break
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
  
  tactileControls[button] = true
  return button
end

--removes a button
function tactile.removeButton(button)
  assert(button, 'button is nil')
  tactileControls[button] = nil
end

--get an axis value, adjusted for deadzone
local function getAxisValue (value)
  return math.abs(value) > tactileDeadzone and value or 0
end

--joystick axis detector
function tactile.addAnalogAxisDetector(axis, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = {}
  
  function detector.getValue()
    local joystick = tactileJoysticks[joystickNum]
    return joystick and getAxisValue(joystick:getGamepadAxis(axis)) or 0
  end

  return detector
end

--keyboard axis detector
function tactile.addBinaryAxisDetector(negative, positive)
  assert(negative, 'negative is nil')
  assert(positive, 'positive is nil')

  local detector = {}
  
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

--holds axis detectors
function tactile.addAxis(...)
  local detectors = { ... }
  local axis = {}

  function axis.getValue()
    --set the overall value to the first non-zero axis detector value
    for k, detector in ipairs(detectors) do
      local value = detector.getValue()
      if value ~= 0 then
        return value
      end
    end
    return 0
  end

  return axis
end

--holds two axes and calculates a vector (length limited to 1)
function tactile.addAxisPair(xAxis, yAxis)
  assert(xAxis, 'xAxis is nil')
  assert(yAxis, 'yAxis is nil')

  local axisPair = {}

  function axisPair:getValue()
    local x = xAxis.getValue()
    local y = yAxis.getValue()

    --normalize if length is more than 1
    local len = math.sqrt(x ^ 2 + y ^ 2)
    if len > 1 then
      x = x / len
      y = y / len
    end
    
    return x, y
  end

  return axisPair
end

function tactile.update()

  --update controls
  for control in pairs(tactileControls) do
    control.update()
  end

end

--refreshes the joysticks list
function tactile.getJoysticks()
  tactileJoysticks = love.joystick.getJoysticks()
end

return tactile
