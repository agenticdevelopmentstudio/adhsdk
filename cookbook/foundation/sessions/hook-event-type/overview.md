
`HookEventType` is a `String`-backed, `CaseIterable`, `Sendable` enum of the Claude Code hook events a session daemon captures: 27 events Claude Code emits plus `StatusLine`, which only the status-line dispatcher produces. Each raw value is the event name exactly as it appears in a hook envelope.

The enum also holds the classification rules the ingest path applies to a raw event type string and its `hook_data`: whether the event is evidence the session did something (`isActivity`), whether it may decide the session's working, idle or waiting state (`setsTurnState`), what it says about subagents (`subagentClock`), and the SQLite table name for its detail rows (`tableName`). The rules take the raw string, not a case, so an event type this build does not model still gets an answer.

