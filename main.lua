function ButtonDisplay(x, y, button)
  local buttonDisplay = {}
  buttonDisplay.x             = x
  buttonDisplay.y             = y
  buttonDisplay.button        = button
  buttonDisplay.pressedAlpha  = 0
  buttonDisplay.releasedAlpha = 0

  function buttonDisplay:update (dt)
    if self.button.pressed then
      self.pressedAlpha = 255
    end
    if self.button.released then
      self.releasedAlpha = 255
    end

    self.pressedAlpha = self.pressedAlpha - 1500 * dt
    self.releasedAlpha = self.releasedAlpha - 1500 * dt
    if self.pressedAlpha < 0 then
      self.pressedAlpha = 0
    end
    if self.releasedAlpha < 0 then
      self.releasedAlpha = 0
    end
  end

  function buttonDisplay:draw()
    if self.button.down then
      love.graphics.setColor(79, 102, 66, 255)
      love.graphics.rectangle('fill', self.x, self.y, 50, 50)
    end

    love.graphics.setColor(213, 194, 128, self.pressedAlpha)
    love.graphics.rectangle('fill', self.x, self.y, 50, 50)

    love.graphics.setColor(126, 179, 181, self.releasedAlpha)
    love.graphics.rectangle('fill', self.x, self.y, 50, 50)

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.rectangle('line', self.x, self.y, 50, 50)
  end

  return buttonDisplay
end

function love.load()
  input = require 'tactile'

  keyboardLeft  = input.addKeyboardButtonDetector('left')
  keyboardRight = input.addKeyboardButtonDetector('right')
  keyboardUp    = input.addKeyboardButtonDetector('up')
  keyboardDown  = input.addKeyboardButtonDetector('down')
  keyboardX     = input.addKeyboardButtonDetector('x')

  gamepadLeft   = input.addAxisButtonDetector('leftx', -.5, 1)
  gamepadRight  = input.addAxisButtonDetector('leftx', .5, 1)
  gamepadUp     = input.addAxisButtonDetector('lefty', -.5, 1)
  gamepadDown   = input.addAxisButtonDetector('lefty', .5, 1)
  gamepadA      = input.addGamepadButtonDetector('a', 1)

  mouseLeft     = input.addMouseButtonDetector('l')

  keyboardXAxis = input.addBinaryAxisDetector(keyboardLeft, keyboardRight)
  keyboardYAxis = input.addBinaryAxisDetector(keyboardUp, keyboardDown)
  gamepadXAxis  = input.addAnalogAxisDetector('leftx', 1)
  gamepadYAxis  = input.addAnalogAxisDetector('lefty', 1)

  left          = input.addButton(keyboardLeft, gamepadLeft)
  right         = input.addButton(keyboardRight, gamepadRight)
  up            = input.addButton(keyboardUp, gamepadUp)
  down          = input.addButton(keyboardDown, gamepadDown)
  primary       = input.addButton(keyboardX, gamepadA, mouseLeft)

  horizontal    = input.addAxis(gamepadXAxis, keyboardXAxis)
  vertical      = input.addAxis(gamepadYAxis, keyboardYAxis)

  axisPair      = input.addAxisPair({gamepadXAxis, gamepadYAxis}, {keyboardXAxis, keyboardYAxis})

  upButtonDisplay      = ButtonDisplay(50, 0, up)
  leftButtonDisplay    = ButtonDisplay(0, 50, left)
  downButtonDisplay    = ButtonDisplay(50, 100, down)
  rightButtonDisplay   = ButtonDisplay(100, 50, right)
  primaryButtonDisplay = ButtonDisplay(0, 0, primary)
end

function love.update(dt)
  input.update()

  upButtonDisplay:update(dt)
  leftButtonDisplay:update(dt)
  downButtonDisplay:update(dt)
  rightButtonDisplay:update(dt)
  primaryButtonDisplay:update(dt)
end

function love.draw()
  love.graphics.push()
  love.graphics.translate(120, 120)

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.circle('line', 0, 0, 100, 100)
  love.graphics.circle('line', 0, 0, 100 * input.deadzone, 100 * input.deadzone)
  love.graphics.circle('fill', axisPair.x * 100, axisPair.y * 100, 5, 100)
  love.graphics.printf('The circle represents an axis pair (read: analog stick x and y components). It can be operated by the left analog stick on joystick 1 or the arrow keys. The dot should not leave the outer circle. The inner circle is the deadzone.', -75, 120, 150, 'center')

  love.graphics.pop()

  love.graphics.push()
  love.graphics.translate(350, 45)

  upButtonDisplay:draw()
  leftButtonDisplay:draw()
  downButtonDisplay:draw()
  rightButtonDisplay:draw()
  love.graphics.printf('These are 4 directional buttons. They light up when held down, and flash when pressed or released. These can be operated by both the left analog stick on joystick 1 and the arrow keys.', 0, 220, 150, 'center')

  love.graphics.pop()

  love.graphics.push()
  love.graphics.translate(650, 100)

  primaryButtonDisplay:draw()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.printf('This is a button that is activated by the X key, the A button on joystick 1, or the left mouse button.', -50, 220, 150, 'center')

  love.graphics.pop()
end
