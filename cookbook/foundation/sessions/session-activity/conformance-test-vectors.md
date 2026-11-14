
The test class `SessionWatcherSessionActivityTests` (macOS test target) reaches `derive` through `SessionWatcherSession.activity`, which passes `isActive: status == .active`. In the vectors, "ended" means `isActive` is `false`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-activity-001 | turn-idle-events, derive-idle-without-subagent | Test `testFinishedTurnsReadAsIdle`: active session, `lastEventType` each of `Stop`, `StopFailure`, `Interrupted`, `SessionStart`, `SessionEnd`, `""`, no subagent | `idle` for each |
| session-activity-002 | turn-waiting-events, derive-turn-passthrough | Test `testRequestsForTheUserReadAsWaiting`: active, `lastEventType` each of `Notification`, `PermissionRequest`, `Elicitation` | `waiting` for each |
| session-activity-003 | turn-working-default, derive-turn-passthrough | Test `testTurnInFlightReadsAsWorking`: active, `lastEventType` each of `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure` | `working` for each |
| session-activity-004 | derive-inactive-idle | Test `testAnEndedSessionIsIdleWhateverItLastDid`: not active, `lastEventType` `PreToolUse` | `idle` |
| session-activity-005 | derive-subagent-promotes-idle | Test `testASessionWaitingOnASubagentReadsAsWorking`: active, `subagentWorking` true, `lastEventType` each of `Stop`, `StopFailure`, `Interrupted`, `SessionStart`, `""` | `working` for each |
| session-activity-006 | derive-subagent-never-over-waiting | Test `testALiveSubagentNeverOverridesWaiting`: active, `subagentWorking` true, `lastEventType` each of `Notification`, `PermissionRequest`, `Elicitation` | `waiting` for each |
| session-activity-007 | derive-inactive-idle | Test `testAnEndedSessionIsIdleEvenWithASubagentStampLeftBehind`: not active, `subagentWorking` true, `lastEventType` `Stop` | `idle` |
| session-activity-008 | turn-working-default | `turnActivity(lastEventType: "SomeFutureEvent")` | `working` |
| session-activity-009 | turn-exact-match | `turnActivity(lastEventType: "stop")` and `turnActivity(lastEventType: " Stop")` | `working` for both, because neither matches `"Stop"` exactly |
| session-activity-010 | derive-inactive-idle | `derive(isActive: false, lastEventType: "PermissionRequest", subagentWorking: false)` | `idle`, not `waiting` |
| session-activity-011 | activity-raw-values, activity-case-iterable | Read `SessionActivity.allCases` and each `rawValue` | `[working, idle, waiting]` with raw values `"working"`, `"idle"`, `"waiting"` |
| session-activity-012 | turn-ignores-liveness | `turnActivity(lastEventType: "SessionEnd")` | `idle`; the call has no liveness argument |

