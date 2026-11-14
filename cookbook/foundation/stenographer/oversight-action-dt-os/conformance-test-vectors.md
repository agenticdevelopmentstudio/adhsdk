
No test beside the source exercises these shapes; the vectors are derived from the declarations and doc comments.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| oversight-action-dt-os-001 | target-blocked | `OversightActionTargetDTO.blocked(findingId: 7, reason: "session is mid-response")` | `findingId` 7, `actionable` false, `reason` as given, `sessionId`, `termProgram`, `termSessionId`, `injectText` all empty, `pid` 0 |
| oversight-action-dt-os-002 | target-fields, target-actionable, target-reason | `OversightActionTargetDTO(findingId: 7, actionable: true, reason: "", sessionId: "s1", termProgram: "iTerm.app", termSessionId: "w0t0p0:ABC", pid: 42, injectText: "/compact")` | each field reads back; `reason` is empty |
| oversight-action-dt-os-003 | target-term-session-id | the same with `termSessionId: ""` | constructs; `termSessionId` is empty |
| oversight-action-dt-os-004 | target-do-not-act | any target with `actionable` false | a consumer does not inject and shows `reason` |
| oversight-action-dt-os-005 | target-terminal-and | `actionable` true and a client whose injector does not support `Apple_Terminal`, with `termProgram` `Apple_Terminal` | the control stays disabled |
| oversight-action-dt-os-006 | result-succeeded, result-status | `OversightActResultDTO(findingId: 7, succeeded: true, status: "acted", reason: "")` | each field reads back |
| oversight-action-dt-os-007 | result-status, result-reason | `OversightActResultDTO(findingId: 7, succeeded: false, status: "resolved", reason: "already resolved")` | `status` is the current status; `reason` is non-empty |
| oversight-action-dt-os-008 | result-status | `OversightActResultDTO(findingId: 9, succeeded: false, status: "", reason: "not found")` | `status` is empty |
| oversight-action-dt-os-012 | result-status | `OversightActionService.result(for: .failed("boom"), findingId: 7)` | `succeeded` false, `status` empty, `reason` `boom` |
| oversight-action-dt-os-013 | result-status | `StenographerHTTPClient.actOnOversightFinding` against a non-2xx reply | `succeeded` false, `status` empty, `reason` the route's `error` text or `HTTP <code>` |
| oversight-action-dt-os-009 | conformance-protocols | two targets built from identical arguments | they compare equal |
| oversight-action-dt-os-010 | conformance-protocols | encode then decode a target and a result | the decoded values equal the originals |
| oversight-action-dt-os-011 | no-validation | `OversightActionTargetDTO(findingId: 1, actionable: true, reason: "x", ...)` | constructs without error |

