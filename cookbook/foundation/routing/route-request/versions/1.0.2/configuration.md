
None — `RouteRequest` reads no environment variable or settings key. Callers supply the paging default and ceiling per call (`boundedLimit(default:max:)`), and the timestamp parameter name (`validatedTimestamp(_:)`). The `limit`, `offset` and `since` key names are fixed by the accessors that read them (`limit` and `offset` inside the paging bounds). `activitySince` reads no key: it takes the text and uses `since` only as the parameter name in its rejection message.

