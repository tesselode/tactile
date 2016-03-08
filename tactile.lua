local tactile = {}

local function any(t, f)
  for i = 1, #t do
    if f(t[i]) then
      return true
    end
  end
  return false
end

local Control = {}

function Control:addAxisDetector(f)
  table.insert(self.axisDetectors, f)
end

function Control:addPositiveButtonDetector(f)
  table.insert(self.positiveButtonDetectors, f)
end

function Control:addNegativeButtonDetector(f)
  table.insert(self.negativeButtonDetectors, f)
end

function Control:addButtonDetectors(negative, positive)
  self:addNegativeButtonDetector(negative)
  self:addPositiveButtonDetector(positive)
end

function Control:getValue()
  local negativeDown = any(self.negativeButtonDetectors, function(f)
    return f()
  end)
  local positiveDown = any(self.positiveButtonDetectors, function(f)
    return f()
  end)

  if negativeDown and positiveDown then
    return 0
  elseif negativeDown then
    return -1
  elseif positiveDown then
    return 1
  else
    for i = #self.axisDetectors, 1, -1 do
      local value = self.axisDetectors[i]()
      if math.abs(value) > self.deadzone then
        return value
      end
    end
    return 0
  end
end

function tactile.newControl()
  local control = {
    deadzone = .5,
    axisDetectors = {},
    positiveButtonDetectors = {},
    negativeButtonDetectors = {},
  }

  setmetatable(control, {__index = Control})
  return control
end

return tactile
