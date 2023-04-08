local HttpService = game:GetService("HttpService")

local Packages = script.Parent.Parent.Packages
local Promise = require(Packages.promise)
local Sift = require(Packages.sift)

local Types = require(script.Parent.Parent.Types)

local DefaultDriver = {}
DefaultDriver.__index = DefaultDriver

function DefaultDriver.new(super)
	local self = {}
	self.super = super

	setmetatable(self, DefaultDriver)
	return self
end

function DefaultDriver:addRequest(options: Types.GQLRequestBody, headers: { [string]: string })
	return Promise.new(function(resolve, reject)
		local encodeSuccess, encodedBody = pcall(HttpService.JSONEncode, HttpService, options)
		if not encodeSuccess then
			return reject(encodedBody)
		end

		local requestSuccess, request = pcall(HttpService.RequestAsync, HttpService, {
			Url = self.super.uri,
			Method = "POST",
			Headers = Sift.Dictionary.merge(headers, {
				["Content-Type"] = "application/json",
			}),
			Body = encodedBody,
		})
		if not requestSuccess then
			return reject({}, request)
		end
		if not request.Body then
			return reject({}, `No body in response ({request.StatusCode} {request.StatusMessage})`)
		end

		local decodeSuccess, decodedBody = pcall(HttpService.JSONDecode, HttpService, request.Body)
		if not decodeSuccess then
			return reject({}, `Could not decode response body: {decodedBody}`)
		end

		if decodedBody.errors then
			return reject(
				decodedBody.data or {},
				table.concat(
					Sift.Array.map(decodedBody.errors, function(err)
						local errMessage = err.message

						if err.locations then
							errMessage = errMessage .. "("

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

		return resolve(decodedBody.data or {})
	end)
end

return DefaultDriver
