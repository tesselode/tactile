function love.load (args)
  input = require 'input'

  input:addKeyDetector('leftKey', 'left')
  input:addKeyDetector('rightKey', 'right')
  input:addButton('horizontal', {'leftKey', 'rightKey'})
end

function love.update (dt)
  input:update(dt)
end

function love.keypressed (key)
  if key == 'escape' then
    love.event.quit()
  end
end
