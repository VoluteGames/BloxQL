local HttpService = game:GetService("HttpService")

local BatchedQueryDriver = {}
BatchedQueryDriver.__index = BatchedQueryDriver

function BatchedQueryDriver.new()
	-- local self = {}
	-- self.queue = {}

	-- while task.wait(timeout) do
	-- 	for _, itm in pairs(self.queue) do
	-- 		HttpService:RequestAsync(itm)
	-- 	end
	-- end

	-- setmetatable(self, BatchedQueryDriver)
	-- return self
end

function BatchedQueryDriver:AddRequest(body: string, options, headers)
	table.insert(self.queue, { Body = body, Headers = headers })
end

return BatchedQueryDriver
