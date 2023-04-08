local Sift = require(script.Parent.Packages.sift)

return Sift.Dictionary.map(script:GetChildren(), function(driver)
	return require(driver), driver.Name
end)
