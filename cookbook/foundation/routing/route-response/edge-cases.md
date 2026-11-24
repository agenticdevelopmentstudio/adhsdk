
- **Null / empty input**: An empty body is allowed (`noContent`, and any `RouteResponse` built with empty `Data`). An empty error message is encoded through the same builder as a pretty-printed object whose `error` value is the empty string (derived; no test beside the source).
- **Boundary values**: `status` is any `Int` with no range check; a caller that passes a value outside the HTTP range gets it stored unchanged. A date is written to whole seconds, so sub-second precision is dropped by the ISO-8601 strategy.
- **Malformed input**: A message containing a quote, backslash or newline MUST yield valid JSON because the body is encoded, not spliced (test: errorBodyIsValidJSONThatDecodesBackToTheMessage). Non-ASCII text is encoded by `JSONEncoder` as given.
- **Encoding failure**: A value that cannot be encoded MUST yield `{}` with the requested status; the failure is dropped by `try?` and the response gives the caller no signal that the real body was lost. The doc comment declares this contract, so it is a fact, not a gap.
- **Concurrent access**: A `RouteResponse` is an immutable `Sendable` value, and `makeJSONEncoder()` returns a fresh encoder each call, so handlers running concurrently never share an encoder.
- **Error states**: No builder throws. The only failure path is the encoding fallback above.
- **Offline / disconnected state**: Not applicable: the type performs no network access; the daemon's HTTP layer sends it.
- **Cancellation and timeouts**: Not applicable: every builder is a synchronous in-memory computation.

