local BaseDriver = {}

function BaseDriver.new()
  local self = {}
  setmetatable(self, BaseDriver)
  return self
end

function BaseDriver:AddQuery()
  
end

return BaseDriver
