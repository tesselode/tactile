function love.load()
  tactile = require 'tactile'
  detector = tactile:addKeyboardButtonDetector('left')
end

function love.update(dt)
  print(detector())
end