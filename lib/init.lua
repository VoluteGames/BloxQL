local Promise = require(script.Packages.promise)
local Types = require(script.Types)

local Document = require(script.Document)

local BloxQL = {}
BloxQL.__index = BloxQL

-- Creates a client
function BloxQL.new(config: Types.Config)
	local self = {}

	if not config.uri or typeof(config.uri) ~= "string" then
		error("BloxQL: config.uri must be a string")
	end
	self.uri = config.uri

	self.headers = config.headers or function()
		return {}
	end

	self.driver = config.driver or BloxQL.Drivers.Default
	self.driver = self.driver.new(self, config.driverConfig or {})

	setmetatable(self, BloxQL)
	return self
end

function BloxQL:makeDocument(...)
	return Document.new(self, ...)
end

BloxQL.Drivers = require(script.Drivers)

return BloxQL
