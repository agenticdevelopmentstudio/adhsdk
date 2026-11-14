
An ordered list of route handlers. Each handler either claims a request by returning a response or declines it by returning `nil`. `RouteTable` is a `Sendable` struct over `Handler`, a `@Sendable` async function from `RouteRequest` to an optional `RouteResponse`. It dispatches a request to the first handler that claims it, merges two tables in order, and builds a handler for one exact method and path. It is transport-free: a daemon's HTTP layer converts its own request into `RouteRequest`, calls `handle`, and treats `nil` as no route.

