
Every vector is a direct call to the Core functions `SessionActivity.derive(isActive:lastEventType:subagentWorking:)` or `SessionActivity.turnActivity(lastEventType:)`; a port tests them at that level. In the vectors, "ended" means `isActive` is `false`. The Swift tests listed in the Input column live in the macOS test class `SessionWatcherSessionActivityTests`, which reaches `derive` through `SessionWatcherSession.activity`; no test sits beside the Core file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-activity-001 | turn-idle-events, derive-idle-without-subagent | Test `testFinishedTurnsReadAsIdle`: active session, `lastEventType` each of `Stop`, `StopFailure`, `Interrupted`, `SessionStart`, `SessionEnd`, `""`, no subagent | `idle` for each |
| session-activity-002 | turn-waiting-events, derive-turn-passthrough | Test `testRequestsForTheUserReadAsWaiting`: active, `lastEventType` each of `Notification`, `PermissionRequest`, `Elicitation` | `waiting` for each |
| session-activity-003 | turn-working-default, derive-turn-passthrough | Test `testTurnInFlightReadsAsWorking`: active, `lastEventType` each of `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure` | `working` for each |
| session-activity-004 | derive-inactive-idle | Test `testAnEndedSessionIsIdleWhateverItLastDid`: not active, `lastEventType` `PreToolUse` | `idle` |
| session-activity-005 | derive-subagent-promotes-idle | Test `testASessionWaitingOnASubagentReadsAsWorking`: active, `subagentWorking` true, `lastEventType` each of `Stop`, `StopFailure`, `Interrupted`, `SessionStart`, `SessionEnd`, `""` (the test covers all but `SessionEnd`; `derive-subagent-promotes-idle` covers every `idle` turn, so `SessionEnd` with a live subagent on an active session reads `working`) | `working` for each |
| session-activity-006 | derive-subagent-never-over-waiting | Test `testALiveSubagentNeverOverridesWaiting`: active, `subagentWorking` true, `lastEventType` each of `Notification`, `PermissionRequest`, `Elicitation` | `waiting` for each |
| session-activity-007 | derive-inactive-idle | Test `testAnEndedSessionIsIdleEvenWithASubagentStampLeftBehind`: not active, `subagentWorking` true, `lastEventType` `Stop` | `idle` |
| session-activity-008 | turn-working-default | `turnActivity(lastEventType: "SomeFutureEvent")` | `working` |
| session-activity-009 | turn-exact-match | `turnActivity(lastEventType:)` with each of `"stop"`, `"STOP"` and `" Stop"` | `working` for each, because none matches `"Stop"` exactly |
| session-activity-010 | derive-inactive-idle | `derive(isActive: false, lastEventType: "PermissionRequest", subagentWorking: false)` | `idle`, not `waiting` |
| session-activity-011 | activity-raw-values, activity-case-iterable | Read `SessionActivity.allCases` and each `rawValue` | `[working, idle, waiting]` with raw values `"working"`, `"idle"`, `"waiting"` |
| session-activity-012 | turn-ignores-liveness | `turnActivity(lastEventType: "SessionEnd")`; plus a static check that the function's signature has only the `lastEventType` parameter | `idle`; no liveness or subagent input exists to change it |
| session-activity-013 | derive-total | `derive` and `turnActivity` called with `lastEventType` `""`, `"Stop"`, `"Notification"`, `"SomeFutureEvent"` and each of `isActive`, `subagentWorking` true and false | a `SessionActivity` returns for every combination; nothing throws and nothing is optional |
| session-activity-014 | derive-turn-passthrough | `derive(isActive: true, lastEventType: "PreToolUse", subagentWorking: true)` | `working`; the subagent flag changes nothing when the turn already reads `working` |
