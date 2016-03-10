local tactile = require 'tactile'

local horizontal = tactile.newControl()
horizontal:addAxis(tactile.gamepadAxis(1, 'leftx'))
horizontal:addButtonPair(
  tactile.keys('a', 'left'),
  tactile.keys('d', 'right')
)

local vertical = tactile.newControl()
vertical:addAxis(tactile.gamepadAxis(1, 'lefty'))
vertical:addButtonPair(
  tactile.keys('w', 'up'),
  tactile.keys('s', 'down')
)

local boost = tactile.newControl()
boost:addButton(tactile.keys 'z')
boost:addButton(tactile.gamepadButtons(1, 'x'))

local player = {x = 400, y = 300}

function love.update(dt)
  local inputVector = {x = horizontal:getValue(), y = vertical:getValue()}
  local len = (inputVector.x^2 + inputVector.y^2)^.5
  if len > 1 then
    inputVector.x = inputVector.x / len
    inputVector.y = inputVector.y / len
  end

  local speed = boost:isDown() and 400 or 200
  player.x = player.x + speed * dt * inputVector.x
  player.y = player.y + speed * dt * inputVector.y
end

function love.draw()
  love.graphics.circle('fill', player.x, player.y, 16, 100)
end
