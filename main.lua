function love.load()
  tactile = require 'tactile'
  
  keyboardLeft  = tactile.key('left')
  keyboardRight = tactile.key('right')
  keyboardXAxis = tactile.binaryStick(keyboardLeft, keyboardRight)
  gamepadXAxis  = tactile.analogStick('leftx', 1)
  
  horizontal    = tactile:addAxis(keyboardXAxis, gamepadXAxis)
end

function love.update(dt)
  tactile:update(dt)
  print(horizontal.value)
end