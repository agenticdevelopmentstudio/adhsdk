
`RouteResponse` has one user-facing string of its own, the default `notFound` message `Not found`, which is hardcoded English and is not localized. It is an API error text read by clients, not a UI string; any other message arrives from the caller.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline literal) | `Not found` | Default message of `notFound(_:)`. |

