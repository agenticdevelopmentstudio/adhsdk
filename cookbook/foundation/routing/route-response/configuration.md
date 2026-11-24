
None — `RouteResponse` reads no environment variable or settings key. The wire encoder's strategies are fixed in `makeJSONEncoder()` and cannot be changed by a caller; `json(_:status:)` always uses it. Callers supply `status`, `contentType` and `headers` through the initializer.

