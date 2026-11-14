
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-status-001 | status-raw-values | `SessionStatus.active.rawValue`, `SessionStatus.stale.rawValue`, `SessionStatus.ended.rawValue` | `"active"`, `"stale"`, `"ended"` |
| session-status-002 | status-raw-values, status-raw-init-optional | `SessionStatus(rawValue: "ended")` | `.ended` |
| session-status-003 | status-raw-init-optional | `SessionStatus(rawValue: "Active")` | `nil`; the match is case-sensitive |
| session-status-004 | status-raw-init-optional | `SessionStatus(rawValue: "")` | `nil` |
| session-status-005 | status-raw-init-optional | `SessionStatus(rawValue: "closed")` | `nil` |
| session-status-006 | status-raw-values, status-stored-as-raw | A session row whose status column holds `"active"`, compared with `SessionStatus.active.rawValue` | Equal; the row counts as active in the liveness pass |
| session-status-007 | active-meaning | Test in `LivenessServiceTests`: a live `claude` process maps to a session not yet `active` | The session is set to `active` and the status-change callback receives `active` |
| session-status-008 | ended-meaning | Test in `LivenessServiceTests`: an active session with a non-empty `cwd` and no live process | The session is set to `ended` and the callback receives `ended` |
| session-status-009 | stale-declared | Decode a stored value `"stale"` with `SessionStatus(rawValue:)` | `.stale` |
| session-status-010 | status-published-as-raw | `SessionEventEncoding.encodeSessionStatus(sessionId: "s1", status: .stale)` | JSON whose `status` is `"stale"` |

