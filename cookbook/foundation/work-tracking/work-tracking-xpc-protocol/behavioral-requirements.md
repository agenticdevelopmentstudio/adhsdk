
- **objc-protocol**: The protocol MUST be an Objective-C protocol (`@objc`), because XPC dispatches by selector.
- **selectors-stable**: The four selectors MUST keep their names and argument labels, because the two sides agree by selector: `workTrackingSetPreferences(_:reply:)`, `workTrackingStatus(reply:)`, `workTrackingRecheckPermissions(reply:)` and `workTrackingSpans(since:limit:reply:)`.
- **json-snake-case**: Every body and every reply MUST be JSON in snake-case keys, per the protocol comment; ISO-8601 dates are the client decoder's reading.
- **set-preferences-body**: The body of `workTrackingSetPreferences` MUST be an encoded `WorkTrackingPreferences`.
- **set-preferences-reply**: `workTrackingSetPreferences` MUST reply the encoded `WorkTrackingStatus` after applying, and MUST reply empty `Data` when it did not apply.
- **status-reply**: `workTrackingStatus` MUST reply an encoded `WorkTrackingStatus`, and MUST reply empty `Data` on failure.
- **recheck-reply**: `workTrackingRecheckPermissions` MUST re-check Accessibility and reply the new status.
- **recheck-explicit**: A caller SHOULD invoke `workTrackingRecheckPermissions` only from a user-driven action, because the doc comment calls it "the one explicit, user-driven check" of Accessibility. This states intent and has no test vector; a set-preferences that turns tracking on is also answered after a live Accessibility check (see Edge Cases).
- **spans-reply**: `workTrackingSpans` MUST reply an array of `Data`, each element one encoded `ActivitySpanDTO`, newest first.
- **spans-since**: A nil `since` MUST mean any start; a non-nil `since` is a string whose format the source does not state.
- **spans-limit**: `limit` MUST be passed through as the caller's `Int`; the protocol states no bound on it.
- **spans-failure-row**: A spans read that failed MUST reply the one element `WorkTrackingWire.readFailedRow`, which is `{"work_tracking_read_failed":true}` (its key is the fixed wire constant `WorkTrackingWire.readFailedKey`), so a failure never reads as "no activity".
- **spans-empty-is-none**: A successful read with no spans MUST reply an empty array, which means no activity.
- **reply-once-async**: Each selector MUST deliver its answer through its `reply` closure, which is `@escaping`, so the daemon may call it after the selector returns.
- **no-error-channel**: The protocol MUST NOT carry a Swift `Error` or a reason string; the caller learns of failure only from empty data or the sentinel row, and not why.

