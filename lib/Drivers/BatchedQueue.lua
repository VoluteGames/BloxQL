local HttpService = game:GetService("HttpService")

local Packages = script.Parent.Parent.Packages
local Sift = require(Packages.sift)
local Promise = require(Packages.promise)

local Types = require(script.Parent.Parent.Types)

local DefaultDriver = require(script.Parent.Default)

local BatchedQueueDriver = {}
BatchedQueueDriver.__index = BatchedQueueDriver

function BatchedQueueDriver.new(
	super,
	config: {
		requestAsync: (Types.RequestAsyncOptions) -> any,
		interval: number?,
		maxRequestSize: number?,
		maxRetries: number?,
	}
)
	local self = {}
	self.super = super
	self.defaultDriver = DefaultDriver.new(super, { requestAsync = config.requestAsync })
	self.interval = config.interval or 10
	self.maxRequestSize = config.maxRequestSize or 95000 -- in bytes, default is just below 100kb, the default max for express
	self.maxRetries = config.maxRetries or 0
	self.queue = {}

	task.spawn(function()
		while task.wait(self.interval) do
			if #self.queue > 0 then
				local queuedItems = self.queue
				self.queue = {}

				-- Remove queries in excess of the max request size
				local requestItems = {}
				local totalSize = 2 -- []
				local insertPosition = 0

				for _, item in ipairs(queuedItems) do
					local encodedItem = HttpService:JSONEncode(item.options)
					local itemSize = #encodedItem

					if totalSize + itemSize > self.maxRequestSize then
						insertPosition += 1
						self.queue = Sift.Array.insert(self.queue, insertPosition, item)

						continue
					end

					totalSize += itemSize
					table.insert(requestItems, item)
				end

				if #requestItems == 0 then
					return
				end

				-- Make the request
				local requestsMapped = Sift.Array.map(requestItems, function(item)
					return item.options
				end)

				local function rejectAll(...)
					for _, item in ipairs(requestItems) do
						item.reject(...)
					end
				end

				local encodeSuccess, encodedBody = pcall(HttpService.JSONEncode, HttpService, requestsMapped)
				if not encodeSuccess then
					return rejectAll(encodedBody)
				end

				local currentRetry = 0
				local function makeRequest()
					local requestSuccess, request = pcall(self.defaultDriver.requestAsync, {
						Url = self.super.uri,
						Method = "POST",
						Headers = Sift.Dictionary.merge(
							unpack(Sift.Array.map(requestItems, function(item)
								return item.headers
							end)),
							{
								["Content-Type"] = "application/json",
							}
						),
						Body = encodedBody,
					})

					local function attemptRetry(errorMessage: any)
						currentRetry += 1

						if currentRetry <= self.maxRetries then
							return makeRequest()
						else
							return rejectAll({}, errorMessage)
						end
					end

					if not requestSuccess then
						return attemptRetry(request)
					end
					if not request.Body then
						return attemptRetry(`No body in response ({request.StatusCode} {request.StatusMessage})`)
					end

					local decodeSuccess, decodedBody = pcall(HttpService.JSONDecode, HttpService, request.Body)
					if not decodeSuccess and request.StatusCode < 400 then
						return attemptRetry(`Could not decode response body: {decodedBody}`)
					end

					if request.StatusCode >= 400 then
						local errorMessage = ""

						if decodedBody and decodedBody.errors then
							errorMessage = "\n"
								.. table.concat(
									Sift.Array.map(decodedBody.errors, function(error)
										return error.message
									end),
									"\n"
								)
						end

						return attemptRetry(
							`Request failed ({request.StatusCode} {request.StatusMessage}){errorMessage}`
						)
					end

					for index, response in ipairs(decodedBody) do
						local item = requestItems[index]

						if item then
							self.defaultDriver
								:readResponse(response, item.driverOptions.parse, item.driverOptions.rawErrors)
								:andThen(item.resolve, item.reject)
						end
					end
				end

				makeRequest()
			end
		end
	end)

	setmetatable(self, BatchedQueueDriver)
	return self
end

function BatchedQueueDriver:addRequest(
	options: Types.GQLRequestBody,
	headers: { [string]: string },
	driverOptions: table
)
	return Promise.new(function(resolve, reject)
		table.insert(self.queue, {
			options = options,
			headers = headers,
			resolve = resolve,
			reject = reject,
			driverOptions = driverOptions,
		})
	end)
end

return BatchedQueueDriver
