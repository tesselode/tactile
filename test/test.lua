local tactile = require 'tactile'

local function test_tactile()
  -- initial setup
  local leftKey, rightKey = false, false
  local leftStick = 0
  local horizontal = tactile.newControl()
    :addAxis(function() return leftStick end)
    :addButtonPair(
      function() return leftKey end,
      function() return rightKey end
    )

  local xKey = false
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
end
