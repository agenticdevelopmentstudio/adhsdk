
- **Empty event type**: `lastEventType` of `""` MUST read `idle` (a session that has recorded no turn event), and with a live subagent `derive` MUST read `working`. Covered by session-activity-001 and session-activity-005.
- **Unknown event type**: A string the switch does not list, such as a hook event added later, MUST read `working`. This is the default branch, so a new event reads as mid-turn until the mapping is updated.
- **Case and whitespace**: `"stop"`, `"STOP"` and `" Stop"` MUST read `working`; the match is exact. Covered by session-activity-009.
- **Ended session with stale inputs**: A session whose process is gone MUST read `idle` even when `lastEventType` is mid-turn or `subagentWorking` is still stamped true. The liveness check runs first.
- **Subagent and waiting**: `subagentWorking` MUST NOT lower a `waiting` reading; a session blocked on a permission prompt still needs the user.
- **Subagent and working**: `subagentWorking` has no effect when the turn already reads `working`. Covered by session-activity-014.
- **Boundary values**: Not applicable: there are no numeric inputs; the only inputs are two booleans and a string.
- **Concurrent access**: Not applicable: both functions are static, pure and hold no state; the enum is `Sendable`.
- **Error states and offline**: Not applicable: nothing is read from disk or network and no function throws.
- **Cancellation and timeouts**: Not applicable: both functions are synchronous and return immediately.

