function love.load (args)
  input = require 'input'

  input:addGamepadButtonDetector('gamepadShoot', 'a', 1)
  input:addKeyboardButtonDetector('keyboardShoot', 'x')
  input:addButton('shoot', {'gamepadShoot', 'keyboardShoot'})
end

function love.update (dt)
  input:update(dt)

  if input:pressed('shoot') then
    print('pressed')
  end
  if input:released('shoot') then
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
  love.graphics.print(tostring(input:isDown('shoot')))
end
