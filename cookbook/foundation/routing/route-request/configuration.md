
None — `RouteRequest` reads no environment variable or settings key. Callers supply the paging default and ceiling per call (`boundedLimit(default:max:)`), and the timestamp parameter name (`validatedTimestamp(_:)`). The `limit`, `offset` and `since` key names are fixed by the accessors that read them (`limit` and `offset` inside the paging bounds, `since` inside `activitySince`).

