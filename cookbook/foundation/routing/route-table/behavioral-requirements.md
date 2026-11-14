
- **handler-type**: `Handler` MUST be an async function that takes a `RouteRequest` and returns `RouteResponse?`, and MUST be `@Sendable`. In Swift it is `typealias Handler = @Sendable (RouteRequest) async -> RouteResponse?`.
- **init-handlers**: `init` MUST store the given handlers in the given order and MUST default to an empty list.
- **first-claim-wins**: `handle(request)` MUST call the handlers in order and MUST return the first non-nil response.
- **later-handlers-skipped**: Once a handler has claimed a request, `handle(request)` MUST NOT call any later handler.
- **declined-handlers-fall-through**: A handler that returns `nil` MUST leave the request for the next handler.
- **none-claims-is-nil**: `handle(request)` MUST return `nil` when no handler claims the request, including for an empty table.
- **handle-is-async-sequential**: `handle(request)` MUST be `async` and MUST await each handler before calling the next; handlers MUST NOT run in parallel for one request.
- **merging-order**: `merging(other)` MUST return a new table holding this table's handlers first and then `other`'s, so this table's handlers take precedence.
- **merging-non-mutating**: `merging(other)` MUST NOT change either operand.
- **exact-handler-claims-method-and-path**: `exact(method, components, respond)` MUST be a static function on `RouteTable`, declared `static func exact(_ method: String, _ components: [String], _ respond: @escaping @Sendable (RouteRequest) async -> RouteResponse) -> Handler`, and MUST return a handler that calls `respond` and returns its response only when the request `method` equals `method` and the request `pathComponents` equal `components`.
- **exact-handler-declines-otherwise**: The `exact` handler MUST return `nil`, without calling `respond`, when the method differs or the path components differ in value, count or order.
- **exact-method-case-sensitive**: The `exact` handler MUST compare `method` as an exact string; `get` does not match `GET`.
- **exact-path-via-components**: The `exact` handler MUST compare the request's `pathComponents`, so empty segments in the path are ignored (`//a/` matches `["a"]`) and the query string is not part of the path. The empty-segment rule comes from `RouteRequest.pathComponents` (see Route Request ([adhsdk.ingredient.foundation.routing.route-request](cookbook:1a8e345f-c602-4ccb-8880-432b1deac6ac))).
- **exact-responder-always-responds**: The `respond` closure of `exact` MUST return a non-optional `RouteResponse`, so an `exact` handler cannot decline after matching.
- **table-is-immutable**: A `RouteTable` MUST hold no state other than its immutable handler list, so no operation on a table changes what that table's `handle` returns afterward; `merging` returns a new table and leaves both operands unchanged (see **merging-non-mutating**).

