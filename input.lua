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

function button (detectors)
  local self = {}
  self.detectors = detectors or {}
  self.prev = false
  self.current = false

  function self:addDetector (detector)
    table.insert(self.detectors, detector)
  end

  function self:update ()
    self.prev = self.current
    self.current = false
    
    for k, v in pairs(self.detectors) do
      --update detector
      v:preUpdate()
      v:update()
      v:postUpdate()

      --trigger the button if any of the detectors are triggered
      if v.current then
        self.current = true
      end
    end

    self.pressed = self.current and not self.prev
    self.released = self.prev and not self.current
  end

  return self
end
