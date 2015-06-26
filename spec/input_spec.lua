_G.love = {}
love.joystick = {}
function love.joystick.getJoysticks ()
  return {}
end

describe('input', function()
  describe(':addButtonDetector', function()
    it('requires a name (string) and a key (string)', function()
      local input = require 'tactile'

      assert.has.error(function()
        input:addKeyboardButtonDetector()
      end)
      assert.has.error(function()
        input:addKeyboardButtonDetector('name')
      end)
      assert.has_no.errors(function()
        input:addKeyboardButtonDetector('name', 'key')
      end)
    end)

    it('adds a button detector to input.buttonDetectors', function()
      local input = require 'tactile'
      input:addKeyboardButtonDetector('test', 'test')

      assert.truthy(input.buttonDetectors.test.key)
    end)
  end)
end)
