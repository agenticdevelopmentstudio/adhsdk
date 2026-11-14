
The source has no test of `SessionEventEncoding` beside it. `RecordingSink` (database test support) is a conforming sink that records each call, and the vectors that use it are traced to it. The ingestion tests in the database test target use that sink to assert what was published.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-event-sink-001 | encode-status-fields, encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .active)` | The bytes of `{"session_id":"s1","status":"active"}` |
| session-event-sink-002 | encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .ended)` | `status` is `"ended"` |
| session-event-sink-003 | encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .stale)` | `status` is `"stale"` |
| session-event-sink-004 | encode-snake-case | `encode` of a struct with property `lastEventType` | JSON key `last_event_type` |
| session-event-sink-005 | encode-iso8601 | `encode` of a struct holding the `Date` for 2026-01-01T00:00:00Z | The value is the string `"2026-01-01T00:00:00Z"` |
| session-event-sink-006 | encode-sorted-keys | `encode` of a struct with properties declared `zeta` then `alpha` | `alpha` appears before `zeta` in the bytes |
| session-event-sink-007 | encode-sorted-keys, encode-fresh-encoder | Encode the same value twice | The two byte sequences are equal |
| session-event-sink-008 | encode-optional-result | `encode` of a value whose `encode(to:)` throws, or that holds a non-finite `Double` | `nil`, with no error raised |
| session-event-sink-009 | sink-broadcast-signature, broadcast-payload-prebuilt | A `RecordingSink` receives `broadcast(eventType: "Stop", payload: bytes, sessionId: "s1")` | `events` holds one entry with event type `"Stop"`, the same bytes and session id `"s1"` |
| session-event-sink-010 | broadcast-session-filter | `broadcast(eventType: "Stop", payload: bytes, sessionId: nil)` on a `RecordingSink` | The recorded `sessionId` is `nil` |
| session-event-sink-011 | sink-status-signature | `broadcastSessionStatus(sessionId: "s1", status: .ended)` on a `RecordingSink` | `statuses` holds `("s1", .ended)` |
| session-event-sink-012 | sink-no-delivery-signal | A sink whose transport has no subscribers receives `broadcast` | The call returns normally and the caller sees no error |

