function love.load()
  tactile = require 'tactile'
  keyboardLeft  = tactile:addKeyboardButtonDetector('left')
  keyboardRight = tactile:addKeyboardButtonDetector('right')
  eitherLeftOrRight = tactile:addButton(keyboardLeft, keyboardRight)
end

function love.update(dt)
  tactile:update()
  print(eitherLeftOrRight.down)
end