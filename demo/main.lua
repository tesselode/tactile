local tactile = require 'tactile'
local vector = require 'vector'

function love.load()
  Control = {
    Horizontal = tactile.newControl()
      :addAxis(tactile.gamepadAxis(1, 'leftx'))
      :addButtonPair(tactile.keys('a', 'left'), tactile.keys('d', 'right')),
    Vertical = tactile.newControl()
      :addAxis(tactile.gamepadAxis(1, 'lefty'))
      :addButtonPair(tactile.keys('w', 'up'), tactile.keys('s', 'down')),
    Fire = tactile.newControl()
      :addAxis(tactile.gamepadAxis(1, 'triggerleft'))
      :addAxis(tactile.gamepadAxis(1, 'triggerright'))
      :addButton(tactile.gamepadButtons(1, 'a'))
      :addButton(tactile.keys 'x')
  }

  player = {pos = vector(400, 300), speed = 400}
end

function love.update(dt)
  for _, control in pairs(Control) do
    control:update()
  end

  local inputVector = vector(Control.Horizontal:getValue(),
    Control.Vertical:getValue())
  if inputVector:len() > 1 then
    inputVector:normalizeInplace()
  end

  player.pos = player.pos + player.speed * inputVector * dt
end

function love.draw()
  love.graphics.circle('fill', player.pos.x, player.pos.y, 16, 100)
end
