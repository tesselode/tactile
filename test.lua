local tactile = require 'tactile'

-- initial setup
local leftKey, rightKey = false, false
local leftStick = 0
local xKey = false

local horizontal = tactile.newControl()
  :addAxis(function() return leftStick end)
  :addButtonPair(
    function() return leftKey end,
    function() return rightKey end
  )

local fire = tactile.newControl()
  :addButton(function() return xKey end)

-- test: control value is zero when all detectors are zero
local function test_initialValues()
  assert(horizontal:_calculateValue() == 0)
end

-- test: control obeys deadzone
local function test_obeysDeadzone()
  leftStick = .4
  assert(horizontal:_calculateValue() == 0)
end

-- test: control:getValue() works in general
local function test_getValue()
  leftStick = -.8
  assert(horizontal:_calculateValue() == -.8)
end

-- test: detectors can override other detectors
local function test_detectorPrecedence()
  rightKey = true
  assert(horizontal:_calculateValue() == 1)
end

-- test: negative and positive buttons cancel each other out
local function test_buttonPairBehavior()
  leftKey = true
  assert(horizontal:_calculateValue() == -.8)
end

-- test: single buttons detectors
local function test_buttonBehavior()
  assert(fire:_calculateValue() == 0)
  xKey = true
  assert(fire:_calculateValue() == 1)
end

-- test: update functionality
local function test_update()
  horizontal:update()
  assert(horizontal._currentValue == -.8)
  assert(horizontal._previousValue == 0)

  leftStick = 0
  horizontal:update()
  assert(horizontal._currentValue == 0)
  assert(horizontal._previousValue == -.8)
end

-- test: getValue function
local function test_getValue()
  leftStick = .8
  horizontal:update()
  assert(horizontal:getValue() == .8)
  assert(horizontal() == horizontal:getValue())
end

-- test: isDown/pressed/released
local function test_isDownPressedReleased()
  leftStick = 0
  horizontal:update()
  horizontal:update()
  assert(not horizontal:isDown())
  assert(not horizontal:pressed())
  assert(not horizontal:released())

  leftStick = 1
  horizontal:update()
  assert(horizontal:isDown())
  assert(horizontal:pressed())
  assert(not horizontal:released())

  horizontal:update()
  assert(horizontal:isDown())
  assert(not horizontal:pressed())
  assert(not horizontal:released())

  leftStick = 0
  horizontal:update()
  assert(not horizontal:isDown())
  assert(not horizontal:pressed())
  assert(horizontal:released())
end
