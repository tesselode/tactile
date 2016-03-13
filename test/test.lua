local tactile = require 'tactile'

local leftKey, rightKey = false, false
local leftStick = 0

local horizontal = tactile.newControl()
  :addAxis(function() return leftStick end)
  :addButtonPair(
    function() return leftKey end,
    function() return rightKey end
  )

local function test_controlValueIsZeroWhenNoInput()
  assert(horizontal:getValue() == 0)
end

leftStick = .4

local function test_controlObeysDeadzone()
  assert(horizontal:getValue() == 0)
end
