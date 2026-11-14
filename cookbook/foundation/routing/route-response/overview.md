
A response as shared routes produce it: no transport and no framework. A daemon's HTTP layer converts it into its own response type. `RouteResponse` is a `Sendable`, `Equatable` struct holding `status`, `body`, `contentType` and `headers`, plus static builders: `makeJSONEncoder()` (the wire encoder), `json(_:status:)`, `error(_:status:)`, `notFound(_:)` and the `noContent` constant.

