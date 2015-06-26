--This is just for testing! You can safely ignore this.

function love.load (args)
  input = require 'tactile'

  input:addKeyboardButtonDetector('keyboardShoot', 'x')
  input:addButton('shoot', {'keyboardShoot'})
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
