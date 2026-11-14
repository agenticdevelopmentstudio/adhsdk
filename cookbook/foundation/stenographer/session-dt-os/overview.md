
Four serializable records transferred over XPC and HTTP between the Stenographer daemon, the app and the CLI. `SessionDTO` is one tracked Claude Code session. `SessionEventDTO` is one recorded hook event. `SessionDetailDTO` pairs a session with its newest events (the body of `GET /sessions/:id`, the XPC `getSessionDetail`, and what `steno session` prints). `HealthDTO` is the daemon's liveness probe.

All four are immutable values with `let` fields. Their wire spelling is the stenographer-wide snake_case strategy. Most fields are Strings; timestamps travel as strings in the daemon's SQLite `datetime` form and are never parsed here. `SessionDTO` has a hand-written decoder that tolerates payloads from an older daemon. The types hold no behavior: how a session is enriched, how activity is derived and how health figures are measured belong to the daemon.

