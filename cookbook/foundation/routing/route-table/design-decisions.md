
**Decision**: A handler claims a request by returning a response and declines by returning `nil`, and the first claim wins.
**Rationale**: The source defines routing as an ordered list with that rule, so a route written once against `RouteRequest` can be mounted by any daemon and the order of the list is the only precedence (test: theFirstNonNilHandlerWins).
**Approved**: pending

**Decision**: `merging` places this table's handlers before `other`'s.
**Rationale**: The doc comment fixes that order, which lets a daemon put its own routes ahead of shared ones and have them win (test: mergingTriesSelfBeforeOther).
**Approved**: pending

**Decision**: `exact` compares `pathComponents`, not the raw path.
**Rationale**: The source matches on the components list so trailing and doubled slashes do not change the match; the `GET /` and `GET /a/b` cases pin the boundary (test: exactClaimsOnlyItsMethodAndPath).
**Approved**: pending

**Decision**: Handlers run sequentially for one request and cannot throw.
**Rationale**: The source loop awaits each handler in turn and the `Handler` type is not `throws`, so one request's handlers are tried in list order and a handler has no way to signal failure to the table; any error response is a `RouteResponse` the handler itself returns.
**Approved**: pending

