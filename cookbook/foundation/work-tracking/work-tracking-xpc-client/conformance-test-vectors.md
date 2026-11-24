
Vectors 001 through 010 are backed by `WorkTrackingXPCClientTests`, which drives the client through a scripted transport. Vectors 011 through 014, 016 and 017 are backed by `WorkTrackingXPCClientConformanceTests`. Vector 015 is spec-only: `WorkTrackingPreferences` cannot fail to encode, so no test can reach it.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-xpc-client-001 | status-call, reply-decoder | Reply literal with `enabled` true, `accessibility` granted, `write_failures` 2, `last_error` "x" and a `current_span` (test `testStatusDecodesSnakeCase`) | status with `enabled` true, `.granted`, `writeFailures` 2, `lastError` "x", `currentSpan.bundleId` "com.x" |
| work-tracking-xpc-client-002 | status-empty-nil | Reply empty `Data` (test `testEmptyReplyIsNil`) | `status()` and `recheckPermissions()` return nil |
| work-tracking-xpc-client-003 | status-unreadable-nil | Reply `not json` (same test) | `status()` returns nil |
| work-tracking-xpc-client-004 | set-preferences-body, set-preferences-no-retry | `setPreferences` with added `["com.a"]`, removed `["com.b"]`, 30 days (test `testSetPreferencesSendsSnakeCaseBody`) | body text contains `added_bundle_ids`; body decodes to the same preferences; `retries` is 0 |
| work-tracking-xpc-client-005 | set-preferences-reply | Reply is an encoded status with `enabled` true (test `testSetPreferencesSendsSnakeCaseBody`) | returned status has `enabled` true |
| work-tracking-xpc-client-006 | set-preferences-timeout | Any `setPreferences` (test `testSetPreferencesWaitsLongerThanTheAccessibilityStall`) | timeout is greater than 10 s and `retries` is 0 |
| work-tracking-xpc-client-007 | recheck-call, recheck-timeout | `recheckPermissions` (test `testRecheckWaitsLongerThanTheAccessibilityStall`) | timeout is greater than 10 s (15 s) and `retries` is 0 |
| work-tracking-xpc-client-008 | spans-order | Two rows, ids `b` then `a` (test `testSpansDecodeNewestFirstAsSent`) | `spans` ids are `["b","a"]` with `bundleId` "com.x" and `startedAt` as sent |
| work-tracking-xpc-client-009 | spans-failure-nil | Rows are `[readFailedRow]` (test `testAFailedSpansReadIsNilNotEmpty`) | `spans` returns nil |
| work-tracking-xpc-client-010 | spans-empty | Rows are `[]` (same test) | `spans` returns an empty array |
| work-tracking-xpc-client-011 | status-call | `status()` (spec-only) | the call carries `timeout` nil and `retries` 0 |
| work-tracking-xpc-client-012 | spans-failure-nil | Two good rows and the failure row last (spec-only) | `spans` returns nil, not two spans |
| work-tracking-xpc-client-013 | status-throw-nil | Transport throws (spec-only) | `status()` returns nil |
| work-tracking-xpc-client-014 | list-row-sentinel | (spec-only) Element `{"work_tracking_read_failed":false}` decoded as `WorkTrackingListRow` of a span | falls through to decoding a span, and throws because the span keys are missing |
| work-tracking-xpc-client-015 | set-preferences-encode-failure | Preferences that cannot be encoded (spec-only) | `setPreferences` returns nil and the transport receives no call |
| work-tracking-xpc-client-016 | spans-throw-nil | Rows contain an element that is neither a span nor the failure row, such as `{"x":1}` (spec-only) | `spans` returns nil |
| work-tracking-xpc-client-017 | status-throw-nil | Transport throws during `setPreferences` and during `recheckPermissions` (spec-only) | each returns nil |
