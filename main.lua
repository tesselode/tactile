local tactile = require 'tactile'

local horizontal = tactile.newControl()
horizontal:addButtonPair(
  tactile.keys('left', 'a'),
  tactile.keys('right', 'd')
)
horizontal:addAxisDetector(tactile.gamepadAxis(1, 'leftx'))

function love.update(dt)
  horizontal:update()

  if horizontal:pressed() then
    print 'pressed'
  end
  if horizontal:released() then
    print 'released'
  end
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end

function love.draw()
  love.graphics.print(tostring(horizontal:isDown()))
end
