local tactile = require 'tactile'

local function test_tactile()
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
  assert(horizontal:_calculateValue() == 0)

  -- test: control obeys deadzone
  leftStick = .4
  assert(horizontal:_calculateValue() == 0)

  -- test: control:getValue() works in general
  leftStick = -.8
  assert(horizontal:_calculateValue() == -.8)

  -- test: detectors can override other detectors
  rightKey = true
  assert(horizontal:_calculateValue() == 1)

  -- test: negative and positive buttons cancel each other out
  leftKey = true
  assert(horizontal:_calculateValue() == -.8)

  -- test: single buttons detectors
  assert(fire:_calculateValue() == 0)
  xKey = true
  assert(fire:_calculateValue() == 1)

  -- test: update functionality
  horizontal:update()
  assert(horizontal._currentValue == -.8 and horizontal._previousValue == 0)
  leftStick = 0
  horizontal:update()
  assert(horizontal._currentValue == 0 and horizontal._previousValue == -.8)

  -- test: isDown/pressed/released
  leftStick = 0
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
