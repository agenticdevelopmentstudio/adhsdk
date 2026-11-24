
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hook-event-type-001 | case-count-pinned, case-list | `HookEventType.allCases.count` | 28 (test `caseCountIsPinned`) |
| hook-event-type-002 | table-name | `HookEventType.preToolUse.tableName` | `pre_tool_use_events` (test `tableNameIsSnakeCaseWithEventsSuffix`) |
| hook-event-type-003 | table-name | `.postToolUseFailure.tableName`, `.statusLine.tableName`, `.stop.tableName`, `.cwdChanged.tableName` | `post_tool_use_failure_events`, `status_line_events`, `stop_events`, `cwd_changed_events` |
| hook-event-type-004 | is-activity-false-for-ambient, ambient-event-types | `isActivity("ConfigChange")` | false (test `ambientTypesAreNotActivityAndUnknownTypesAre`); likewise `StatusLine` and `InstructionsLoaded` |
| hook-event-type-005 | is-activity-true-otherwise | `isActivity("SomethingNew")`, `isActivity("")` | true, true (first from the same test) |
| hook-event-type-006 | is-activity-exact-match | `isActivity("configchange")` | true |
| hook-event-type-007 | sets-turn-state-ambient-or-off-turn | `setsTurnState("ConfigChange", [:])`, `("SubagentStop", [:])`, `("FileChanged", [:])`, `("PreCompact", [:])` | false for each |
| hook-event-type-008 | sets-turn-state-default | `setsTurnState("PreToolUse", [:])`, then with `["agent_id": "a1"]`, then with `["agent_id": ""]` | true, false, true |
| hook-event-type-009 | sets-turn-state-blocking-requests | `setsTurnState("PermissionRequest", ["agent_id": "a1"])`, `("Elicitation", ["agent_id": "a1"])` | true, true |
| hook-event-type-010 | sets-turn-state-notification | `notification_type` of `idle_prompt`, `permission_prompt`, `elicitation_dialog`, `""`, absent, `5` (a number) | false, true, true, true, true, true |
| hook-event-type-011 | sets-turn-state-session-start | `source` of `compact`, `startup`, absent | false, true, true |
| hook-event-type-012 | sets-turn-state-default | `setsTurnState("Stop", [:])`, `("SomethingNew", [:])`, `("SomethingNew", ["agent_id": "a1"])` | true, true, false |
| hook-event-type-014 | subagent-clock-stop | `subagentClock("SubagentStop", [:])` and with an `agent_id` | -1, -1 |
| hook-event-type-015 | subagent-clock-activity | `subagentClock("PreToolUse", ["agent_id": "a1"])`, `("SubagentStart", ["agent_id": "a1"])` | 1, 1 |
| hook-event-type-016 | subagent-clock-stop-failure | `subagentClock("StopFailure", ["agent_id": "a1"])`, and `("StopFailure", [:])` | -1, 0 |
| hook-event-type-017 | subagent-clock-no-agent | `subagentClock("Stop", [:])`, `("PreToolUse", ["agent_id": ""])`, `("PreToolUse", ["agent_id": 7])` | 0, 0, 0 |
| hook-event-type-018 | waiting-notification-types, turn-ending-event-types, off-turn-event-types, interrupted-event-type | read the four constants | `ambientEventTypes` is `{ConfigChange, StatusLine, InstructionsLoaded}`; `offTurnEventTypes` is `{SubagentStart, SubagentStop, TaskCreated, TaskCompleted, TeammateIdle, PreCompact, PostCompact, FileChanged}`; `waitingNotificationTypes` is `{permission_prompt, elicitation_dialog}`; `turnEndingEventTypes` is `{Stop, StopFailure, SessionEnd}`; `interruptedEventType == "Interrupted"` (untested: no test pins the members) |

