local Exports = {}

for name, driver in pairs(script:GetChildren()) do
  Exports[name] = require(driver)
end

return Exports
