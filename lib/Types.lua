export type Config = {
	driver: table,
	driverConfig: table,
	uri: string,
	headers: (self) -> { [string]: string } | { [string]: string },
}

export type GQLRequestBody = {
	query: string,
	variables: { [string]: any },
}

return nil
