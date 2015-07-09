function love.load()
  tactile = require 'tactile'
  testAxis = tactile:addGamepadAxisDetector('leftx', 1)
end

function love.update(dt)
  print(testAxis())
end