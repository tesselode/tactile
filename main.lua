local tactile = require 'tactile'

local horizontal = tactile.newControl()
horizontal:addButtonPair(function()
  return love.keyboard.isDown 'left'
end, function()
  return love.keyboard.isDown 'right'
end)
horizontal:addButtonPair(function()
  return love.keyboard.isDown 'a'
end, function()
  return love.keyboard.isDown 'd'
end)
horizontal:addAxisDetector(function()
  return love.joystick.getJoysticks()[1]:getGamepadAxis 'leftx'
end)

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end

function love.draw()
  love.graphics.print(horizontal:getValue())
end
