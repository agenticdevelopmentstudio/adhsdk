
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| parsed-event-001 | initializer, event-type, timestamp, hook-data, account-email, context | `ParsedEvent(eventType: "PreToolUse", timestamp: "2026-01-01T00:00:00Z", hookData: ["session_id": "s-1", "tool_name": "Bash"], context: nil, accountEmail: "a@b.c")` (the `event()` helper in `IngestSpoolTests`) | each field reads back as given; `context == nil` |
| parsed-event-002 | oauth-account-email, initializer | the same call as 001 | `oauthAccountEmail == nil` |
| parsed-event-003 | oauth-nil-versus-empty | `oauthAccountEmail: ""` | `oauthAccountEmail == ""`, which is not nil |
| parsed-event-004 | oauth-account-email | `oauthAccountEmail: "me@x.y"` | `"me@x.y"` |
| parsed-event-005 | context | `context: ["cwd": "/tmp/p"]` | `context?["cwd"] as? String == "/tmp/p"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`, after the round trip) |
| parsed-event-006 | no-validation, event-type | `eventType: ""`, `hookData: ["session_id": "s-u"]` | constructed without error (what parsing does with it is in the Parse Result ([adhsdk.ingredient.foundation.sessions.parse-result](cookbook:67b656ef-78a2-41ae-a910-f87f527360b1)) vectors) |
| parsed-event-007 | no-validation | `hookData: [:]` | constructed without error; its `sessionId` is `""` (the parse outcome is in the Parse Result ([adhsdk.ingredient.foundation.sessions.parse-result](cookbook:67b656ef-78a2-41ae-a910-f87f527360b1)) vectors) |
| parsed-event-008 | account-email | `accountEmail: ""` | `accountEmail == ""` |
| parsed-event-009 | session-id-accessor | `hookData: ["session_id": "s-rt"]` | `sessionId == "s-rt"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`) |
| parsed-event-010 | immutable-fields | static check (code review or API-surface inspection, not a runtime test): every stored property is declared `let` | no stored property is `var`; assigning to `eventType` on a constant is a compile error |

