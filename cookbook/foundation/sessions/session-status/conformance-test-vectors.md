
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-status-001 | status-raw-values | `SessionStatus.active.rawValue`, `SessionStatus.stale.rawValue`, `SessionStatus.ended.rawValue` | `"active"`, `"stale"`, `"ended"` |
| session-status-002 | status-raw-values, status-raw-init-optional | `SessionStatus(rawValue: "ended")` | `.ended` |
| session-status-003 | status-raw-init-optional | `SessionStatus(rawValue: "Active")` | `nil`; the match is case-sensitive |
| session-status-004 | status-raw-init-optional | `SessionStatus(rawValue: "")` | `nil` |
| session-status-005 | status-raw-init-optional | `SessionStatus(rawValue: "closed")` | `nil` |
| session-status-006 | status-raw-values, status-stored-as-raw | `SessionStatus(rawValue: "active")` and `SessionStatus.active.rawValue == "active"` | `.active`; the stored string and the enum agree |
| session-status-007 | status-cases | `SessionStatus(rawValue:)` for each of `"active"`, `"stale"`, `"ended"` | `.active`, `.stale`, `.ended`; no other raw string yields a value |
| session-status-008 | status-vs-activity | Inspect the enum's API surface | `SessionStatus` offers no operation that returns a `SessionActivity`; activity comes only from `SessionActivity.derive` (Session Activity ([adhsdk.ingredient.foundation.sessions.session-activity](cookbook:bc99bb92-f6b7-4767-8d29-f68ee9e5e2b4))) |
| session-status-009 | stale-declared, status-raw-init-optional | Decode a stored value `"stale"` with `SessionStatus(rawValue:)` | `.stale` |
| session-status-010 | status-published-as-raw | `SessionEventEncoding.encodeSessionStatus(sessionId: "s1", status: .stale)` | JSON whose `status` is `"stale"` |
| session-status-011 | status-sendable | Pass a `SessionStatus` value across a task boundary | Compiles without a `Sendable` diagnostic |
