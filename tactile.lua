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
  table.insert(self.detectors, f)
end

function Control:addPositiveButtonDetector(f)
  table.insert(self.detectors, function()
    if f() then
      return 1
    else
      return 0
    end
  end)
end

function Control:addNegativeButtonDetector(f)
  table.insert(self.detectors, function()
    if f() then
      return -1
    else
      return 0
    end
  end)
end

function Control:addButtonPair(negative, positive)
  table.insert(self.detectors, function()
    local n, p = negative(), positive()
    if n and p then
      return 0
    elseif n then
      return -1
    elseif p then
      return 1
    else
      return 0
    end
  end)
end

function Control:getValue()
  for i = #self.detectors, 1, -1 do
    local value = self.detectors[i]()
    if math.abs(value) > self.deadzone then
      return value
    end
  end
  return 0
end

function tactile.newControl()
  local control = {
    deadzone = .5,
    detectors = {},
  }

  setmetatable(control, {__index = Control})
  return control
end

return tactile
