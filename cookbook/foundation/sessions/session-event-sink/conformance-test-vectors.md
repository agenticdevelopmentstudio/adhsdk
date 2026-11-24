
The source has no test of `SessionEventEncoding` beside it. `RecordingSink` (database test support) is a test double that records each call; the sink vectors below drive it through `EventIngestor`, the real caller, and assert what gets published.
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-event-sink-001 | encode-status-fields, encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .active)` | The bytes of `{"session_id":"s1","status":"active"}` |
| session-event-sink-002 | encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .ended)` | `status` is `"ended"` |
| session-event-sink-003 | encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .stale)` | `status` is `"stale"` |
| session-event-sink-004 | encode-snake-case | `encode` of a struct with property `lastEventType` | JSON key `last_event_type` |
| session-event-sink-005 | encode-iso8601 | `encode` of a struct holding the `Date` for 2026-01-01T00:00:00Z | The value is the string `"2026-01-01T00:00:00Z"` |
| session-event-sink-006 | encode-sorted-keys | `encode` of a struct with properties declared `zeta` then `alpha` | `alpha` appears before `zeta` in the bytes |
| session-event-sink-007 | encode-sorted-keys, encode-stateless | Encode the same value twice, and from several tasks at once | The byte sequences are all equal |
| session-event-sink-008 | encode-optional-result | `encode` of a value whose `encode(to:)` throws, or that holds a non-finite `Double` | `nil`, with no error raised |
| session-event-sink-009 | sink-broadcast-signature, broadcast-payload-prebuilt | Test `testTheDrainWritesASpooledEventAndPublishesIt`: an `EventIngestor` built with a `RecordingSink` drains one spooled event | `sink.events` holds an entry for the event with `sessionId == "s-p2"` and the bytes `SessionEventEncoding.encode` gave for the ingested event |
| session-event-sink-010 | broadcast-session-filter | `broadcast(eventType: "Stop", payload: bytes, sessionId: nil)` on a `RecordingSink` | The recorded `sessionId` is `nil` |
| session-event-sink-011 | sink-status-signature | `EventIngestor.broadcastSessionStatus(sessionId: "s1", status: .ended)` with a `RecordingSink` injected | `statuses` holds `("s1", .ended)` |
| session-event-sink-012 | sink-no-delivery-signal | `EventIngestor` ingests an event while the injected sink delivers to no subscribers (a sink that drops every call) | Ingestion completes and the ingested row is written; the caller sees no error |
| session-event-sink-013 | caller-skips-on-encode-failure | `EventIngestor` ingests an event whose `SessionEventEncoding.encode` returns `nil`, with a `RecordingSink` injected | `sink.events` is empty and no crash occurs |
| session-event-sink-014 | encode-slash-escaping | `encode` of a struct whose string property is `"a/b"` | The bytes contain `a\/b` |
