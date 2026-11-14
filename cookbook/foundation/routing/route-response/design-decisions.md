
**Decision**: `makeJSONEncoder()` returns a new encoder on every call.
**Rationale**: The doc comment on `makeJSONEncoder()` in `RouteResponse.swift` says `JSONEncoder` is a reference type and handlers run concurrently, so a shared instance would be shared mutable state.
**Approved**: pending

**Decision**: The error body is built by encoding a small `ErrorBody` struct through `json(_:status:)`, not by splicing the message into a string.
**Rationale**: The doc comment on `error(_:status:)` in `RouteResponse.swift` says a message containing a quote, backslash or newline would otherwise produce invalid JSON (test: errorBodyIsValidJSONThatDecodesBackToTheMessage).
**Approved**: pending

**Decision**: A value that fails to encode produces `{}` with the requested status rather than a thrown error or an error response.
**Rationale**: The doc comment on `json(_:status:)` in `RouteResponse.swift` states the fallback and keeps the function non-throwing so handlers need no error path (test: aValueThatFailsToEncodeYieldsAnEmptyObject). The cost is that the lost body is not reported, and a client reads `{}` with the requested status (often 200) as an empty success. Alternatives weighed: a 500 `error` body would tell the client the handler failed and would be the safer signal; a log line would tell the operator without changing the response; `{}` with the requested status keeps the signature and every call site unchanged. The source chose `{}`; whether to switch to a 500 body or add a log is the owner's call, which is why this decision stays pending.
**Approved**: pending

**Decision**: `noContent` keeps the default `application/json` content type with an empty body.
**Rationale**: The source builds it with the plain initializer; the test pins the resulting content type (test: noContentIs204WithAnEmptyBody).
**Approved**: pending

