
Vectors 001, 005, 007, 008 and 009 are backed by tests in `WorkTrackingXPCClientTests`; 002, 006, 011, 012, 013 and 014 by `WorkTrackingXPCProtocolConformanceTests`. Vectors 003, 004 and 010 (daemon-side replies) and 015 (a static property) are spec-only.

Derived from the protocol's doc comments and from `WorkTrackingXPCClientTests`, whose `RecordingProxy` conforms to the protocol and captures the set-preferences body, and whose literals show the reply shapes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-xpc-protocol-001 | set-preferences-body, json-snake-case | Client sends `workTrackingSetPreferences` for added ids `["com.a"]` (test `testSetPreferencesSendsSnakeCaseBody`) | the body contains `added_bundle_ids` and decodes to the same preferences |
| work-tracking-xpc-protocol-002 | set-preferences-reply | Daemon applied a change that turns tracking on | reply is an encoded `WorkTrackingStatus` such as `{"enabled":true,"accessibility":"granted","write_failures":0}` |
| work-tracking-xpc-protocol-003 | set-preferences-reply | Daemon did not apply | reply is empty `Data` |
| work-tracking-xpc-protocol-004 | status-reply | Daemon cannot build the status | reply is empty `Data` (zero bytes), which a client treats as failure |
| work-tracking-xpc-protocol-005 | status-reply, json-snake-case | Reply literal with `write_failures`, `last_error` and `current_span` (test `testStatusDecodesSnakeCase`) | decodes to a `WorkTrackingStatus` with those fields |
| work-tracking-xpc-protocol-006 | recheck-reply | Accessibility grant is missing when `workTrackingRecheckPermissions` is called | reply is an encoded status such as `{"enabled":true,"accessibility":"denied","write_failures":0}` |
| work-tracking-xpc-protocol-007 | spans-reply | Two spans stored | two elements, the later `started_at` first (test `testSpansDecodeNewestFirstAsSent`) |
| work-tracking-xpc-protocol-008 | spans-failure-row | Spans read fails | one element equal to `WorkTrackingWire.readFailedRow` (test `testAFailedSpansReadIsNilNotEmpty`) |
| work-tracking-xpc-protocol-009 | spans-empty-is-none | No spans match | empty array (same test) |
| work-tracking-xpc-protocol-010 | spans-since | `since` nil | spans from any start are included |
| work-tracking-xpc-protocol-011 | spans-failure-row | Inspect `WorkTrackingWire.readFailedRow` | the bytes are `{"work_tracking_read_failed":true}` and `readFailedKey` is `work_tracking_read_failed` |
| work-tracking-xpc-protocol-012 | selectors-stable | List the protocol's selector names | exactly `workTrackingSetPreferences:reply:`, `workTrackingStatusWithReply:`, `workTrackingRecheckPermissionsWithReply:`, `workTrackingSpansSince:limit:reply:` |
| work-tracking-xpc-protocol-013 | objc-protocol | Build an `NSXPCInterface(with: WorkTrackingXPCProtocol.self)` (spec-only) | it builds without a runtime error |
| work-tracking-xpc-protocol-014 | reply-once-async | Daemon stub calls the `reply` of `workTrackingStatus` after the selector returned (spec-only) | the caller still receives the reply |
| work-tracking-xpc-protocol-015 | no-error-channel | Inspect each selector's parameter and reply types (spec-only) | none carries an `Error` or a reason string; replies are `Data` or `[Data]` |
