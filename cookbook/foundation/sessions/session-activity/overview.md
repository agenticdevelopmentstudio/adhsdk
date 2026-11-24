
`SessionActivity` says what a session is doing right now: `working`, `idle` or `waiting`. It is separate from `SessionStatus`, which only says whether a process exists. A session can be alive and idle, alive and working, or alive and blocked on the user.

The value is never stored. `SessionActivity.derive(isActive:lastEventType:subagentWorking:)` computes it from what the daemon recorded: whether the process is alive, the last hook event type of the main agent's turn, and the daemon's verdict that a subagent was busy just now. The daemon records what happened and not what it means, so the mapping can change, or learn a new event type, without a schema change.

The enum is the one reading shared by the Sessions window's activity icon and `steno conversation status`, so the two cannot disagree.

The inputs are `isActive` (whether the session's process is alive; `false` forces `idle`), `lastEventType` (the last hook event recorded for the main agent's turn) and `subagentWorking` (the daemon's verdict that a subagent was busy just now). None of them is configuration.

The `waiting` reading of `"Notification"` assumes the daemon records only a Notification that asks for an answer, not the idle reminder sent after every finished turn; recording is the daemon's job, outside this component.

