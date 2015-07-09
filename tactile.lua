local tactile = {}
tactile.__index = tactile

function tactile:addKeyboardButtonDetector(key)
  return function()
    return love.keyboard.isDown(key)
  end
end

function tactile.new()
  return setmetatable({}, tactile)
end

return tactile.new()