local tactile = require 'tactile'
local vector = require 'vector'

function love.load()
  -- set up controls
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

  player = {
    pos = vector(400, 300),
    speed = 400,
    cooldown = 0.15,
    cooldownTimer = 0.15,
  }
  bullets = {}
end

function love.update(dt)
  -- update controls
  for _, control in pairs(Control) do
    control:update()
  end

  -- player movement
  local inputVector = vector(Control.Horizontal(), Control.Vertical())
  if inputVector:len() > 1 then
    inputVector:normalizeInplace()
  end
  player.pos = player.pos + player.speed * inputVector * dt

  -- player shooting
  player.cooldownTimer = player.cooldownTimer - dt
  if Control.Fire:isDown() and player.cooldownTimer < 0 then
    table.insert(bullets, {pos = player.pos:clone(), speed = 800})
    player.cooldownTimer = player.cooldown
  end

  -- update bullets
  for i = #bullets, 1, -1 do
    local bullet = bullets[i]
    bullet.pos.y = bullet.pos.y - bullet.speed * dt
    if bullet.pos.y < -50 then
      bullet.dead = true
    end
    if bullet.dead then
      table.remove(bullets, i)
    end
  end
end

function love.draw()
  -- draw player
  love.graphics.circle('fill', player.pos.x, player.pos.y, 16, 100)

  -- draw bullets
  for i = 1, #bullets do
    local bullet = bullets[i]
    love.graphics.circle('fill', bullet.pos.x, bullet.pos.y, 4, 100)
  end
end
