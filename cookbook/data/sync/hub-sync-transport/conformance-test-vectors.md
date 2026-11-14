
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-sync-transport-001 | cursor-raw-value, decode-pull | `pull(cursor: SyncCursor(rawValue: "c9"), limit: 50)`; the call returns a JSON pull body with one change | The call saw `("c9", 50)`; the result has that change and its cursor |
| hub-sync-transport-002 | cursor-raw-value | `pull(cursor: nil, limit: 10)` | The call saw `(nil, 10)` |
| hub-sync-transport-003 | encode-push | `push` of a request with one op | The call's body decodes back to the same `SyncPushRequest`; the result decodes from the returned body |
| hub-sync-transport-004 | map-unauthorized | The call throws `.unauthorized` | `SyncTransportError.unauthorized` |
| hub-sync-transport-005 | map-resync | The call throws `.resyncRequired` | `.resyncRequired` |
| hub-sync-transport-006 | map-http | The call throws `.http(503)` | `.invalidResponse(statusCode: 503)` |
| hub-sync-transport-007 | map-transport | The call throws `.transport("offline")` | `.transport("offline")` |
| hub-sync-transport-008 | map-coding | The call returns `not json` | `.transport(...)` |
| hub-sync-transport-009 | cancellation-passes | The call throws `CancellationError()` | `CancellationError` |

