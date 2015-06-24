local input = {}
input.detectors = {}
input.buttons = {}

--general detector class
function input:addDetector (name)
  local detector = {}
  detector.prev = false
  detector.current = false

  function detector:preUpdate ()
    detector.prev = detector.current
  end

  function detector:update () end

  function detector:postUpdate ()
    --detect pressed/released
    detector.pressed = detector.current and not detector.prev
    detector.released = detector.prev and not detector.current
  end

  self.detectors[name] = detector
  return(detector)
end

--detects if a keyboard key is down/pressed/released
function input:addKeyDetector (name, key)
  local detector = input:addDetector(name)
  detector.key = key

  function detector:update ()
    detector.current = love.keyboard.isDown(detector.key)
  end

  self.detectors[name] = detector
  return detector
end

--holds detectors
function input:addButton (name, detectors)
  local button = {}
  button.detectors = {}
  for k, v in pairs(detectors) do
    table.insert(button.detectors, input.detectors[v])
  end

  button.prev = false
  button.current = false

  function button:addDetector (detector)
    table.insert(button.detectors, detector)
  end

  function button:update ()
    button.prev = button.current
    button.current = false

    for k, v in pairs(button.detectors) do
      --trigger the button if any of the detectors are triggered
      if v.current then
        button.current = true
      end
    end

    button.pressed = button.current and not button.prev
    button.released = button.prev and not button.current
  end

  self.buttons[name] = button
  return button
end

function input:update ()
  --update detectors
  for k, v in pairs(self.detectors) do
    v:preUpdate()
    v:update()
    v:postUpdate()
  end

  --update buttons
  for k, v in pairs(self.buttons) do
    v:update()
  end
end

--functions to access buttons
function input:isDown (button) return self.buttons[button].current end

function input:pressed (button) return self.buttons[button].pressed end

function input:released (button) return self.buttons[button].released end

return input
