function love.load (args)
  require 'input'

  leftDetector = keyDetector('left')
  rightDetector = keyDetector('right')
  horizontalButton = button({leftDetector, rightDetector})
end

function love.update (dt)
  horizontalButton:update()

  if horizontalButton.pressed then
    print 'pressed'
  end
  if horizontalButton.released then
    print 'released'
  end
end

function love.keypressed (key)
  if key == 'escape' then
    love.event.quit()
  end
end

function love.draw ()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.print(tostring(horizontalButton.current))
end
