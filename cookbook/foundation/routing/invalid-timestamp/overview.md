
`InvalidTimestamp` is the failure type for a rejected `?since=` style query parameter. The source comment gives the reason it exists: `Result`'s failure must be an `Error`, and a retroactive `extension String: Error` would make every string in the process a throwable, a cure worse than the bare `String` it replaces. It is a public struct that carries one human-readable `message`, compares by value, and prints as its message. It holds no parsing logic; `RouteRequest` builds it when a timestamp does not parse.

