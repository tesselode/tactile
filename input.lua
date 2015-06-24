function detector ()
  local self = {}
  self.prev = false
  self.current = false

  function self:preUpdate ()
    self.prev = self.current
  end

  function self:update () end

  function self:postUpdate ()
    self.pressed = self.current and not self.prev
    self.released = self.prev and not self.current
  end

  return self
end

function keyDetector (key)
  local self = detector()
  self.key = key

  function self:update ()
    self.current = love.keyboard.isDown(self.key)
  end

  return self
end
