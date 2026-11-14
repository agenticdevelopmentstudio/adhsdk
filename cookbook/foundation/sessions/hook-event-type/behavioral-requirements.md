
### Cases

- **case-list**: The enum MUST have exactly these 28 cases, each with a raw value equal to its name in UpperCamelCase: `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`, `Stop`, `StopFailure`, `SubagentStart`, `SubagentStop`, `Notification`, `PreCompact`, `PostCompact`, `Setup`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `Elicitation`, `ElicitationResult`, `ConfigChange`, `InstructionsLoaded`, `WorktreeCreate`, `WorktreeRemove`, `CwdChanged`, `FileChanged` and `StatusLine`.
- **case-count-pinned**: `allCases.count` MUST be 28, so adding or removing a case is a visible change (test `caseCountIsPinned`).
- **status-line-synthetic**: `StatusLine` MUST be treated as synthetic: Claude Code does not emit it, the status-line dispatcher forwards each render's stdin payload to `steno hook --event StatusLine`.
- **registration-list**: NEEDS REVIEW: Not implemented in source. The doc comment says the installer "registers exactly this list", but `ClaudeHookConfiguration.defaultHookedEvents` and `ClaudeHookInstaller.hookedEventTypes` filter out `ClaudeHookInstaller.excludedEventTypes` (`WorktreeCreate` and `WorktreeRemove`, which Claude Code treats as delegations, and the synthetic `StatusLine`), so 25 of the 28 cases are registered; the comment or the registration needs to change, and the owner of the installer settles which.

### Activity

- **ambient-event-types**: `ambientEventTypes` MUST be exactly the raw values `ConfigChange`, `StatusLine` and `InstructionsLoaded`: events that fire for reasons unrelated to the session (settings edits fan out to every live session, status-line renders arrive many times per second, instruction-file changes fan out to idle sessions).
- **is-activity-false-for-ambient**: `isActivity(_:)` MUST return false for each raw value in `ambientEventTypes`.
- **is-activity-true-otherwise**: `isActivity(_:)` MUST return true for every other string, including a type this build does not model and the empty string, because a hook not yet modelled is more likely real work than ambient noise.
- **is-activity-exact-match**: `isActivity(_:)` MUST compare the raw string exactly, so `configchange` in another case is activity.
- **ambient-creates-not-moves**: Per the doc comment, a row an ambient event creates from scratch still takes the event's timestamp, and an ambient event must not move a row that already exists; the enforcement is in the ingest store (`EventIngestStore`), which reads `isActivity`, not in this enum.

### Turn state

- **off-turn-event-types**: `offTurnEventTypes` MUST be exactly the raw values `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`, `PreCompact`, `PostCompact` and `FileChanged`: events that report on something other than the main agent's turn.
- **waiting-notification-types**: `waitingNotificationTypes` MUST be exactly `permission_prompt` and `elicitation_dialog`, the `Notification` types that mean the agent is blocked on the user; the rest, above all `idle_prompt` (sent a minute after every finished turn), are informational.
- **turn-ending-event-types**: `turnEndingEventTypes` MUST be exactly `Stop`, `StopFailure` and `SessionEnd`: events after which nothing runs until the user speaks.
- **interrupted-event-type**: `interruptedEventType` MUST be the string `Interrupted`, a synthetic `last_event_type` for a user interrupt (Claude Code fires no hook for one); it is not a case of the enum and is not in any of the sets above.
- **sets-turn-state-ambient-or-off-turn**: `setsTurnState(_:hookData:)` MUST return false when `isActivity` is false or the type is in `offTurnEventTypes`, before any other rule.
- **sets-turn-state-blocking-requests**: `setsTurnState` MUST return true for `PermissionRequest` and `Elicitation` whatever `hook_data` holds, even when it carries an `agent_id`, because a session waiting on the user is waiting either way.
- **sets-turn-state-notification**: For `Notification`, `setsTurnState` MUST return true when `hook_data["notification_type"]` is missing, not a string or empty, and otherwise true only when the value is in `waitingNotificationTypes`.
- **sets-turn-state-session-start**: For `SessionStart`, `setsTurnState` MUST return false only when `hook_data["source"]` is the string `compact`; a missing or non-string `source` returns true.
- **sets-turn-state-default**: For every other type, including an unknown one, `setsTurnState` MUST return true only when `hook_data["agent_id"]` is missing, not a string or empty, so a subagent's hook never sets the main turn's state.
- **sets-turn-state-no-agent-check-for-notification-and-start**: `setsTurnState` does not read `agent_id` for `Notification` or `SessionStart`, so a subagent's waiting `Notification` or non-compact `SessionStart` returns true; this is how the code behaves, though the doc comment says "nor anything a subagent did".

### Subagent clock

- **subagent-clock-stop**: `subagentClock(_:hookData:)` MUST return -1 for `SubagentStop`, whether or not `hook_data` has an `agent_id`; a stop is terminal, one per subagent, so it clears the stamp rather than ageing out.
- **subagent-clock-no-agent**: `subagentClock` MUST return 0 for any other type when `hook_data["agent_id"]` is missing, not a string or empty.
- **subagent-clock-stop-failure**: `subagentClock` MUST return -1 for `StopFailure` carrying a non-empty `agent_id`, because a subagent the API refused is finished and most such subagents never send `SubagentStop`.
- **subagent-clock-activity**: `subagentClock` MUST return 1 for any other type carrying a non-empty `agent_id`, including `SubagentStart`; the caller stamps `sessions.subagent_activity_at` on 1 and clears it on -1.
- **subagent-clock-not-a-counter**: The result is a stamp signal, not a count, because `SubagentStart` is younger than `SubagentStop` and a counter would run negative.

### Table name

- **table-name**: `tableName` MUST insert `_` before every uppercase character that is not first, lower-case every character, and append `_events`, giving the SQLite table for the event type's detail rows (`PreToolUse` becomes `pre_tool_use_events`).

### Concurrency and side effects

- **pure-and-sendable**: The enum is `Sendable`, the four sets and `interruptedEventType` are immutable `static let` values, and every function is a pure computation over its arguments; none reads a file, logs or posts a notification, so any thread MAY call them concurrently.
- **hook-data-untrusted**: `hookData` values are read with `as? String`; a value of another type is treated as absent, and no function throws.

