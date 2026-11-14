
**Shape**

- **activity-cases**: `SessionActivity` MUST have exactly three cases: `working`, `idle` and `waiting`.
- **activity-raw-values**: Each case's `String` raw value MUST equal its case name: `"working"`, `"idle"`, `"waiting"`.
- **activity-case-iterable**: `SessionActivity` MUST conform to `CaseIterable`, listing the cases in the order `working`, `idle`, `waiting`.
- **activity-sendable**: `SessionActivity` MUST conform to `Sendable`.
- **activity-derived-not-stored**: The enum MUST expose no stored or cached activity; callers MUST call `derive` on each read from the recorded inputs.

**Turn activity**

- **turn-waiting-events**: `turnActivity(lastEventType:)` MUST return `waiting` for `"Notification"`, `"PermissionRequest"` and `"Elicitation"`, the events where the agent has handed control back and is waiting on the user.
- **turn-idle-events**: `turnActivity(lastEventType:)` MUST return `idle` for `"Stop"`, `"StopFailure"`, `"Interrupted"`, `"SessionStart"`, `"SessionEnd"` and the empty string. `StopFailure` is a turn ended by an API error; `Interrupted` is the daemon's own record of the user cutting a turn short, which fires no Claude Code hook.
- **turn-working-default**: `turnActivity(lastEventType:)` MUST return `working` for every other string, including `"UserPromptSubmit"`, `"PreToolUse"`, `"PostToolUse"` and `"PostToolUseFailure"`.
- **turn-exact-match**: `turnActivity(lastEventType:)` MUST compare the event type as an exact, case-sensitive string; it MUST NOT trim whitespace or fold case.
- **turn-ignores-liveness**: `turnActivity(lastEventType:)` MUST depend on `lastEventType` alone; it takes no liveness or subagent input.

**Derivation**

- **derive-inactive-idle**: `derive(isActive:lastEventType:subagentWorking:)` MUST return `idle` when `isActive` is `false`, whatever `lastEventType` and `subagentWorking` are.
- **derive-turn-passthrough**: When `isActive` is `true` and `turnActivity(lastEventType:)` returns `working` or `waiting`, `derive` MUST return that value.
- **derive-subagent-promotes-idle**: When `isActive` is `true`, the turn reads `idle` and `subagentWorking` is `true`, `derive` MUST return `working`.
- **derive-subagent-never-over-waiting**: When the turn reads `waiting`, `derive` MUST return `waiting` even if `subagentWorking` is `true`.
- **derive-idle-without-subagent**: When `isActive` is `true`, the turn reads `idle` and `subagentWorking` is `false`, `derive` MUST return `idle`.
- **derive-total**: `derive` and `turnActivity` MUST return a value for every input; neither throws nor returns an optional.
