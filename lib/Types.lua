export type table = {
	[any]: any,
}

export type Config = {
	driver: table,
	driverConfig: table?,
	uri: string,
	headers: (self) -> { [string]: string } | { [string]: string },
}

export type GQLRequestBody = {
	query: string,
	variables: { [string]: any },
}

export type RequestAsyncOptions = {
	Url: string,
	Method: string,
	Headers: { [string]: string },
	Body: string,
}

return nil
