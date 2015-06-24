function love.load (args)
  input = require 'input'

  input:addKeyDetector('leftKey', 'left')
  input:addKeyDetector('rightKey', 'right')
  input:addBinaryAxisDetector('leftAxisLeft', 'leftx', -.5, 1)
  input:addButton('leftButton', {'leftKey', 'leftAxisLeft'})

  input:addJoystickAxisDetector('leftStickX', 'leftx', 1)
  input:addKeyAxisDetector('arrowKeysX', 'leftKey', 'rightKey')
  input:addAxis('horizontal', {'leftStickX', 'arrowKeysX'})
end

function love.update (dt)
  input:update(dt)

  if input:pressed('leftButton') then
    print('pressed')
  end
  if input:released('leftButton') then
    print('released')
  end
end

function love.keypressed (key)
  if key == 'escape' then
    love.event.quit()
  end
end

function love.draw ()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.print(tostring(input:isDown('leftButton')))
  love.graphics.print(tostring(input:getAxis('horizontal')), 0, 10)
end
