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

function love.update(dt)
  horizontal:update()

  if horizontal:pressed(-1) then
    print 'pressed'
  end
  if horizontal:released(1) then
    print 'released'
  end
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end

function love.draw()
  love.graphics.print(tostring(horizontal:isDown()))
end
