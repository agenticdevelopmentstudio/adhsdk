
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| parse-result-001 | empty-is-lost | `""` | `.lostEvent` |
| parse-result-002 | empty-is-lost | `"  \n\t "` | `.lostEvent` |
| parse-result-003 | not-an-object-is-unparseable | `"{not json"` | `.unparseable` |
| parse-result-004 | not-an-object-is-unparseable | `"[]"` and `"null"` | `.unparseable`, `.unparseable` |
| parse-result-005 | missing-event-is-unparseable | `{"hook_data":{"session_id":"s1"}}` | `.unparseable` |
| parse-result-006 | missing-event-is-unparseable | `{"event":"","hook_data":{"session_id":"s-u"}}` (an envelope spooled from an event with an empty type) | `.unparseable` |
| parse-result-007 | missing-event-is-unparseable | `{"event":5,"hook_data":{"session_id":"s1"}}` | `.unparseable` |
| parse-result-008 | missing-session-is-skip | `{"event":"StatusLine","hook_data":{"term_session_id":"t1"}}` | `.skip(reason: "no session_id — not a trackable session event")` |
| parse-result-009 | hook-data-fallback | `{"event":"Stop","hook_data":[]}` | `.skip` |
| parse-result-010 | event-check-before-session-check | `{"hook_data":{}}` | `.unparseable`, not `.skip` |
| parse-result-011 | event-fields, timestamp-default, account-email-default, context-optional | `{"event":"PreToolUse","hook_data":{"session_id":"s1"}}` | `.event` with `eventType == "PreToolUse"`, `timestamp == ""`, `accountEmail == ""`, `context == nil`, `oauthAccountEmail == nil`, `hookData == ["session_id": "s1"]` |
| parse-result-012 | event-fields, context-optional, account-email-default | the envelope written for `ParsedEvent(eventType: "PreToolUse", timestamp: "2026-01-01T00:00:00Z", hookData: [session_id: "s-rt", tool_name: "Bash"], context: ["cwd": "/tmp/p"], accountEmail: "a@b.c")` | `.event` with the same `eventType`, `timestamp`, `sessionId == "s-rt"`, `accountEmail == "a@b.c"` and `context["cwd"] == "/tmp/p"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`) |
| parse-result-013 | single-decoder | a quarantined drop file written by the drainer for event `doomed`, session `s-q` | `.event` with `sessionId == "s-q"` (test `testAQuarantinedFileIsReadableByTheDropFileParser`) |
| parse-result-014 | oauth-email-nil-when-absent | `"oauth_account_email":""` then `"oauth_account_email":"me@x.y"` then the key absent or `null` | `""`, `"me@x.y"`, nil |
| parse-result-015 | context-optional | `"context":"text"` | `.event` with `context == nil` |
| parse-result-016 | extra-keys-ignored | the 011 envelope plus `"unknown":1` | the same `.event` as 011 |
| parse-result-017 | not-an-object-is-unparseable | `{"event":"Stop","hook_data":{"session_id":"s1"}} trailing` | `.unparseable` |
| parse-result-018 | json-null-is-absent | `{"event":"Stop","timestamp":null,"account_email":null,"hook_data":{"session_id":"s1"}}` | `.event` with `timestamp == ""` and `accountEmail == ""` |

