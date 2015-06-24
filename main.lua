function love.load (args)
  require 'input'

  test = keyDetector('left')
end

function love.update (dt)
  test:preUpdate()
  test:update()
  test:postUpdate()

  if test.pressed then
    print 'pressed'
  end
  if test.released then
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
  love.graphics.print(tostring(test.current))
end
