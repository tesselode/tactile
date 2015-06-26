--This is just for testing! You can safely ignore this.

function love.load (args)
  input = require 'tactile'

  input:addKeyboardButtonDetector('keyboardLeft', 'left')
  input:addMouseButtonDetector('leftClick', 'l')
  input:addGamepadButtonDetector('gamepadA', 'a', 1)
end

function love.update (dt)
  input:update(dt)
end

function love.keypressed (key)
  if key == 'escape' then
    love.event.quit()
  end
end

function love.draw ()
  love.graphics.setColor(255, 255, 255, 255)
end
