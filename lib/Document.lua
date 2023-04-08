local HttpService = game:GetService("HttpService")
local Sift = require(script.Parent.Packages.sift)

local Document = {}
Document.__index = Document

function Document.new(super, query: string)
	local self = {}
	self.query = query
	self.super = super
	setmetatable(self, Document)
	return self
end

function Document:__call(options)
	local super = self.super
	local headers = typeof(super.headers) == "function" and super.headers(super) or super.headers

	return self.super.driver:addRequest(
		{ variables = options.variables or {}, query = self.query },
		Sift.Dictionary.merge(headers, options.headers),
		options.driverOptions or {}
	)
end

function Document:Destroy()
	setmetatable(self, nil)
	self.query = nil
	self.super = nil

	self = nil
end

return Document
