
**Decision**: A handler claims a request by returning a response and declines by returning `nil`, and the first claim wins.
**Rationale**: A first-claim rule makes the order of the list the only precedence, so a route written once against `RouteRequest` can be mounted by any daemon and a reader can predict the winner by reading the list. Most-specific-match routing was the alternative; it needs a specificity rule that every port would have to reproduce (test: theFirstNonNilHandlerWins).
**Approved**: pending

**Decision**: `merging` places this table's handlers before `other`'s.
**Rationale**: Putting the receiver first lets a daemon place its own routes ahead of shared ones and have them win. Appending the receiver after `other` was the alternative, and it would make shared routes shadow local ones (test: mergingTriesSelfBeforeOther).
**Approved**: pending

**Decision**: `exact` compares `pathComponents`, not the raw path.
**Rationale**: Matching on the components list means trailing and doubled slashes do not change the match, where comparing the raw path string would make `/a` and `/a/` different routes; the `GET /` and `GET /a/b` cases pin the boundary (test: exactClaimsOnlyItsMethodAndPath).
**Approved**: pending

**Decision**: Handlers run sequentially for one request and cannot throw.
**Rationale**: The source loop awaits each handler in turn and the `Handler` type is not `throws`, so one request's handlers are tried in list order and a handler has no way to signal failure to the table; any error response is a `RouteResponse` the handler itself returns.
**Approved**: pending

