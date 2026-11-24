
**Decision**: The initializer stores arguments verbatim, and sorting, de-duplication and clamping happen only in `normalized()`.
**Rationale**: Callers can build any value, and the layer that persists calls `normalized()` once. This keeps a half-edited form value representable.
**Approved**: pending

**Decision**: A failed list read replies with one element, `{"work_tracking_read_failed":true}`, instead of an error.
**Rationale**: A caller can tell a failed read from an empty list, and billing and work tracking list replies share one failure shape, the same convention as `BillingWire.readFailedRow`.
**Approved**: pending

**Decision**: `isDegraded` is true for `.unknown` as well as `.denied`.
**Rationale**: The source defines degraded as `enabled && accessibility != .granted`, so an unanswered Accessibility state is treated as not granted. `testDegradedOnlyWhenEnabledWithoutGrant` asserts both.
**Approved**: pending

**Decision**: The session id of an app span is `app:` plus the span id, so billing segments from app spans are told apart from other sessions by prefix.
**Rationale**: Billing sessions come from more than one source, so the prefix is the only marker that a segment came from an app span; `spanId(sessionId:)` returns nil for any other session id.
**Approved**: pending

