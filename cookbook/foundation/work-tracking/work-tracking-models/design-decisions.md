
**Decision**: The initializer stores arguments verbatim, and sorting, de-duplication and clamping happen only in `normalized()`.
**Rationale**: The doc comment on `normalized()` says "Sorted, de-duplicated ids; retention clamped into range." Callers can build any value, and the layer that persists calls `normalized()` once. This keeps a half-edited form value representable.
**Approved**: pending

**Decision**: A failed list read replies with one element, `{"work_tracking_read_failed":true}`, instead of an error.
**Rationale**: The doc comment ties this to review F25 and to `BillingWire.readFailedRow`, so list replies share one failure convention across billing and work tracking.
**Approved**: pending

**Decision**: `isDegraded` is true for `.unknown` as well as `.denied`.
**Rationale**: The source defines degraded as `enabled && accessibility != .granted`, so an unanswered Accessibility state is treated as not granted. `testDegradedOnlyWhenEnabledWithoutGrant` asserts both.
**Approved**: pending

**Decision**: The session id of an app span is `app:` plus the span id, so billing segments from app spans are told apart from other sessions by prefix.
**Rationale**: The doc comment calls the prefix "the prefix of a billing segment's session id when an app span made it". `spanId(sessionId:)` returns nil for any other session id.
**Approved**: pending

