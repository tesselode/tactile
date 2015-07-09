function love.load()
  tactile = require 'tactile'
  
  keyboardLeft  = tactile.key('left')
  keyboardRight = tactile.key('right')
  keyboardXAxis = tactile.binaryAxis(keyboardLeft, keyboardRight)
  gamepadXAxis  = tactile.analogStick('leftx', 1)
  
  handler    = tactile.new()
  horizontal = handler:addAxis(keyboardXAxis, gamepadXAxis)
end

function love.update(dt)
  handler:update(dt)
  print(horizontal.value)
end