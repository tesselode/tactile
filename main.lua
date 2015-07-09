function love.load()
  tactile = require 'tactile'
  
  keyboardLeft  = tactile:addKeyboardButtonDetector('left')
  keyboardRight = tactile:addKeyboardButtonDetector('right')
  keyboardXAxis = tactile:addBinaryAxisDetector(keyboardLeft, keyboardRight)
  gamepadXAxis  = tactile:addGamepadAxisDetector('leftx', 1)
  
  horizontal    = tactile:addAxis(keyboardXAxis, gamepadXAxis)
end

function love.update(dt)
  tactile:update(dt)
  print(horizontal.value)
end