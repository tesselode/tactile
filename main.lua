--This is just for testing! You can safely ignore this.

function love.load (args)
  input = require 'input'

  input:addGamepadButtonDetector('gamepadShoot', 'a', 2)
  input:addKeyboardButtonDetector('keyboardShoot', 'x')
  input:addMouseButtonDetector('mouseShoot', 'l')
  input:addAxisButtonDetector('arbitraryShoot', 'leftx', -.5, 1)
  input:addButton('shoot', {'gamepadShoot', 'keyboardShoot', 'mouseShoot', 'arbitraryShoot'})
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
