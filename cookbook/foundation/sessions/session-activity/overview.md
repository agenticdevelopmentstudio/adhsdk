
`SessionActivity` says what a session is doing right now: `working`, `idle` or `waiting`. It is separate from `SessionStatus`, which only says whether a process exists. A session can be alive and idle, alive and working, or alive and blocked on the user.

The value is never stored. `SessionActivity.derive(isActive:lastEventType:subagentWorking:)` computes it from what the daemon recorded: whether the process is alive, the last hook event type of the main agent's turn, and the daemon's verdict that a subagent was busy just now. The daemon records what happened and not what it means, so the mapping can change, or learn a new event type, without a schema change.

The enum is the one reading shared by the Sessions window's activity icon and `steno conversation status`, so the two cannot disagree. In the macOS sources `SessionWatcherSession.activity` calls `derive` with `isActive` set from `status == .active`, and `SessionWatcher.SessionWatcherActivity` is a typealias of `SessionActivity`.

