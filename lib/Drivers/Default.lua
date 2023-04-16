local HttpService = game:GetService("HttpService")

local Packages = script.Parent.Parent.Packages
local Promise = require(Packages.promise)
local Sift = require(Packages.sift)

local Types = require(script.Parent.Parent.Types)

local DefaultDriver = {}
DefaultDriver.__index = DefaultDriver

function DefaultDriver.new(super, config: { requestAsync: (Types.RequestAsyncOptions) -> any, maxRetries: number? })
	local self = {}
	self.super = super
	self.requestAsync = config.requestAsync or function(...)
		return HttpService:RequestAsync(...)
	end
	self.maxRetries = config.maxRetries or 0

	setmetatable(self, DefaultDriver)
	return self
end

function DefaultDriver:addRequest(
	options: Types.GQLRequestBody,
	headers: { [string]: string },
	driverOptions: table,
	currentRetry: number?
)
	return Promise.new(function(resolve, reject)
		self:makeRequest(options, headers, resolve, reject, driverOptions, currentRetry)
	end)
end

function DefaultDriver:makeRequest(
	options: Types.GQLRequestBody,
	headers: { [string]: string },
	resolve: (table) -> nil,
	reject: (table, { string }?) -> nil,
	driverOptions: table,
	currentRetry: number?
)
	local encodeSuccess, encodedBody = pcall(HttpService.JSONEncode, HttpService, options)
	if not encodeSuccess then
		return reject(encodedBody)
	end

	local requestSuccess, request = pcall(self.requestAsync, {
		Url = self.super.uri,
		Method = "POST",
		Headers = Sift.Dictionary.merge(headers, {
			["Content-Type"] = "application/json",
		}),
		Body = encodedBody,
	})
	local function attemptRetry(errorMessage: any)
		currentRetry += 1

		if currentRetry <= self.maxRetries then
			return self:makeRequest(options, headers, resolve, reject, driverOptions, currentRetry)
		else
			return reject({}, errorMessage)
		end
	end

	if not requestSuccess then
		return resolve(attemptRetry(request))
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

		return attemptRetry(`Request failed ({request.StatusCode} {request.StatusMessage}){errorMessage}`)
	end

	return self:readResponse(decodedBody, driverOptions.parse, driverOptions.rawErrors):andThen(resolve, reject)
end

function DefaultDriver:readResponse(
	body: {
		data: table?,
		errors: {
			[number]: {
				message: string,
				locations: {
					[number]: {
						line: number,
						column: number,
					},
				},
				path: {
					[number]: string,
				},
				extensions: {
					[number]: {
						code: string,
						stacktrace: {
							[number]: string,
						},
					},
				},
			},
		}?,
	},
	parse: ((table) -> any)?,
  rawErrors: boolean
)
	return Promise.new(function(resolve, reject)
		if body.errors then
			return reject(
				body.data or {},
				table.concat(
					Sift.Array.map(body.errors, function(err)
						local errMessage = err.message

						if err.locations and not rawErrors then
							errMessage = errMessage .. " ("

							for _, location in pairs(err.locations) do
								errMessage = errMessage .. ` L{location.line}C{location.column}`
							end

							errMessage = errMessage .. " )"
						end

						return errMessage
					end),
					"\n"
				)
			)
		end

		local bodyData = body.data or {}

		return resolve(parse and parse(bodyData) or bodyData)
	end)
end

return DefaultDriver
