function love.load (args)
  input = require 'input'

  input:addKeyDetector('leftKey', 'left')
  input:addKeyDetector('rightKey', 'right')
  input:addButton('horizontal', {'leftKey', 'rightKey'})
end

function love.update (dt)
  input:update(dt)

  if input:pressed('horizontal') then
    print('pressed')
  end
  if input:released('horizontal') then
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
  love.graphics.print(tostring(input:isDown('horizontal')))
end
