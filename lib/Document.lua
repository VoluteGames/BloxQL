local Sift = require(script.Parent.Packages.sift)

local Document = {}
Document.__index = Document

function Document.new(super, query: string, parse: ((table) -> any)?)
	local self = {}
	assert(typeof(query) == "string", "BloxQL: query must be a string")
	self.query = query
	self.parse = parse
	self.super = super
	setmetatable(self, Document)
	return self
end

function Document:__call(options, rawResponse: boolean?, rawErrors: boolean?)
	local super = self.super
	local headers = typeof(super.headers) == "function" and super.headers(super) or super.headers
	local driverOptions = options.driverOptions or {}

	return self.super.driver:addRequest(
		{ variables = options.variables or {}, query = self.query },
		Sift.Dictionary.merge(headers, options.headers),
		Sift.Dictionary.merge(driverOptions, { parse = not rawResponse and self.parse or nil, rawErrors = rawErrors or false })
	)
end

function Document:raw(options)
	return self:__call(options, true)
end

function Document:Destroy()
	setmetatable(self, nil)
	self.query = nil
	self.super = nil

	self = nil
end

return Document
