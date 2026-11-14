
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| parsed-event-envelope-001 | session-id | `hookData: ["session_id": "s-rt"]` | `sessionId == "s-rt"` (untested: the round-trip test `testEnvelopeRoundTripsThroughTheDropFileParser` does not check the accessor alone) |
| parsed-event-envelope-002 | session-id | `hookData: [:]`, and `["session_id": 5]` | `""`, `""` (untested: no test asserts this) |
| parsed-event-envelope-003 | envelope-required-keys, envelope-context-when-present, envelope-oauth-when-resolved | event with `context: nil`, `oauthAccountEmail: nil` | JSON object with exactly the keys `event`, `timestamp`, `hook_data`, `account_email` (untested: no test asserts this) |
| parsed-event-envelope-004 | envelope-context-when-present | event with `context: ["cwd": "/tmp/p"]` | the object also has `context == {"cwd":"/tmp/p"}` (untested: no test asserts this) |
| parsed-event-envelope-005 | envelope-oauth-when-resolved | `oauthAccountEmail: ""` | the object has `oauth_account_email == ""`; with nil the key is absent (untested: no test asserts this) |
| parsed-event-envelope-006 | envelope-round-trip | `PreToolUse`, `2026-01-01T00:00:00Z`, `["session_id": "s-rt", "tool_name": "Bash"]`, context `["cwd": "/tmp/p"]`, `a@b.c`, spooled and read back | parser returns `.event` with the same type, timestamp, `sessionId == "s-rt"`, `accountEmail == "a@b.c"`, `context["cwd"] == "/tmp/p"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`) |
| parsed-event-envelope-007 | envelope-round-trip | a quarantined spool row written as the envelope for event `doomed`, session `s-q` | parser returns `.event` with `sessionId == "s-q"` (test `testAQuarantinedFileIsReadableByTheDropFileParser`) |
| parsed-event-envelope-008 | envelope-round-trip | `oauthAccountEmail` nil, then `""`, then `"me@x.y"` | parsed back as nil, `""`, `"me@x.y"` (untested: no test asserts this) |
| parsed-event-envelope-009 | envelope-round-trip-degenerate | `eventType: ""`, session `s-u` | `envelopeJSON()` succeeds; the parser returns `.unparseable` (test `testAnUnparseableEnvelopeIsQuarantinedWithoutReachingTheDatabase`) |
| parsed-event-envelope-010 | envelope-round-trip-degenerate | event `StatusLine` with `hookData["session_id"] == ""` | encodes; the parser returns `.skip` (test `testAnUntrackableEventIsDiscardedQuietlyAndNeverQuarantined`) |
| parsed-event-envelope-011 | not-serializable-pre-check | `hookData: ["session_id": "s", "when": Date()]`, `eventType: "PreToolUse"` | throws `EnvelopeEncodingError.notSerializable("PreToolUse")` (untested: no test asserts this) |
| parsed-event-envelope-012 | not-serializable-pre-check | `hookData: ["session_id": "s", "n": Double.nan]` | throws `notSerializable` (untested: no test asserts this) |
| parsed-event-envelope-013 | error-description | `EnvelopeEncodingError.notSerializable("Stop").errorDescription` | `Stop payload is not JSON-serializable` (untested: no test asserts this) |
| parsed-event-envelope-014 | not-serializable-pre-check | a non-serializable value inside `context` only | throws `notSerializable`, since `context` is part of the checked envelope (untested: no test asserts this) |
| parsed-event-envelope-015 | error-description | `EnvelopeEncodingError.notSerializable("").errorDescription` | ` payload is not JSON-serializable` with a leading space (untested: no test asserts this) |
| parsed-event-envelope-016 | envelope-required-keys | an event with `timestamp: "x"` and `accountEmail: ""` | the object has `timestamp == "x"` and `account_email == ""`, both JSON strings (untested: no test asserts this) |
