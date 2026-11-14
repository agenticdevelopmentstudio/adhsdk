
Derived from the protocol's doc comments and from `WorkTrackingXPCClientTests`, whose `RecordingProxy` conforms to the protocol and captures the set-preferences body, and whose literals show the reply shapes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-xpc-protocol-001 | set-preferences-body, json-snake-case | Client sends `workTrackingSetPreferences` for added ids `["com.a"]` (test `testSetPreferencesSendsSnakeCaseBody`) | the body contains `added_bundle_ids` and decodes to the same preferences |
| work-tracking-xpc-protocol-002 | set-preferences-reply | Daemon applied the change | reply is an encoded `WorkTrackingStatus` with `enabled` true |
| work-tracking-xpc-protocol-003 | set-preferences-reply | Daemon did not apply | reply is empty `Data` |
| work-tracking-xpc-protocol-004 | status-reply | Daemon failed to build the status | reply is empty `Data` |
| work-tracking-xpc-protocol-005 | status-reply, json-snake-case | Reply literal with `write_failures`, `last_error` and `current_span` (test `testStatusDecodesSnakeCase`) | decodes to a `WorkTrackingStatus` with those fields |
| work-tracking-xpc-protocol-006 | recheck-reply | User asks Check Again | reply is the new encoded status |
| work-tracking-xpc-protocol-007 | spans-reply | Two spans stored | two elements, the later `started_at` first (test `testSpansDecodeNewestFirstAsSent`) |
| work-tracking-xpc-protocol-008 | spans-failure-row | Spans read fails | one element equal to `WorkTrackingWire.readFailedRow` (test `testAFailedSpansReadIsNilNotEmpty`) |
| work-tracking-xpc-protocol-009 | spans-empty-is-none | No spans match | empty array (same test) |
| work-tracking-xpc-protocol-010 | spans-since | `since` nil | spans from any start are included |
| work-tracking-xpc-protocol-011 | spans-failure-row | Inspect `WorkTrackingWire.readFailedRow` | the bytes are `{"work_tracking_read_failed":true}` and `readFailedKey` is `work_tracking_read_failed` |

