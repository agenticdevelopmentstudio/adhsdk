
**Decision**: `makeJSONEncoder()` returns a new encoder on every call.
**Rationale**: The source says `JSONEncoder` is a reference type and handlers run concurrently, so a shared instance would be shared mutable state.
**Approved**: pending

**Decision**: The error body is built by encoding a small `ErrorBody` struct through `json(_:status:)`, not by splicing the message into a string.
**Rationale**: The source says a message containing a quote, backslash or newline would otherwise produce invalid JSON (test: errorBodyIsValidJSONThatDecodesBackToTheMessage).
**Approved**: pending

**Decision**: A value that fails to encode produces `{}` with the requested status rather than a thrown error or an error response.
**Rationale**: The source states the fallback in the doc comment and keeps `json(_:status:)` non-throwing so handlers need no error path; the cost is that the lost body is not reported (test: aValueThatFailsToEncodeYieldsAnEmptyObject).
**Approved**: pending

**Decision**: `noContent` keeps the default `application/json` content type with an empty body.
**Rationale**: The source builds it with the plain initializer; the test pins the resulting content type (test: noContentIs204WithAnEmptyBody).
**Approved**: pending

