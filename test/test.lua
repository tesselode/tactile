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

  -- test: control value is zero when all detectors are zero
  assert(horizontal:_calculateValue() == 0)

  -- test: control obeys deadzone
  leftStick = .4
  assert(horizontal:_calculateValue() == 0)
end
