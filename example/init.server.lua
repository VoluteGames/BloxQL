local ServerScriptService = game:GetService("ServerScriptService")
local BloxQL = require(ServerScriptService:FindFirstChild("BloxQL"))

-- Initialize the client
local client = BloxQL.new({
	driver = BloxQL.Drivers.BatchedQuery,
	uri = "https://countries.trevorblades.com/",
	headers = function(client)
		return { Authorization = "Example" }
	end,
})

local getCountryQuery = client:makeDocument([[
    query getCountry($code: ID!) {
      country(code: $code) {
        name
        native
        currency
      }
    }
  ]])

getCountryQuery({ variables = { code = "IL" }, driverOptions = { immediate = true } }):andThen(print, warn)
getCountryQuery({ variables = { code = "GB" } }):andThen(print, warn)
getCountryQuery({ variables = { code = "US" } }):andThen(print, warn)

client
	:makeDocument([[
    query getContinent($code: ID!) {
      continent(code: $code) {
        name
        countries {
          name
        }
      }
    }
  ]])({ variables = { code = "NA" } })
	:andThen(print, warn)
