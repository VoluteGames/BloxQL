local Promise = require(script.Packages.promise)

local BloxQL = {}

type Config = {
	driver: table,
	uri: string,
	headers: (self) -> { [string]: string } | { [string]: string },
}

-- Creates a client
function BloxQL.new(config: Config)
	local self = {}
	self.uri = config.uri
	self.fetchHeaders = config.fetchHeaders or {}
	self.driver = config.driver.new(self)
  setmetatable(self, BloxQL)
	return self
end

function BloxQL:request(schema: string, variables: table, headers: table?) 
  
end

BloxQL.Drivers = require(script.Drivers)

return BloxQL
