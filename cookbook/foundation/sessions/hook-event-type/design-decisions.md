
**Decision**: Classification functions take the raw event type string, not a case.
**Rationale**: A hook Claude Code adds after this build must still be ingested; unknown types count as activity, since they are more likely real work than ambient noise.
**Approved**: pending

**Decision**: Ambient events do not advance activity, and only main-turn events set turn state.
**Rationale**: One settings save stamped seven untouched sessions with the same second, `StatusLine` arrives many times per second, and subagent and compaction events arrive after a turn has ended; counting them kept finished sessions looking busy.
**Approved**: pending

**Decision**: Blocking requests (`PermissionRequest`, `Elicitation`) set turn state even from a subagent, and a `Notification` without a type reads as waiting.
**Rationale**: The session is waiting on the user either way, and nothing in a typeless notification says it is informational.
**Approved**: pending

**Decision**: `subagentClock` returns a signal (1, -1, 0), and `SubagentStop` and a subagent's `StopFailure` clear it outright.
**Rationale**: Measured over real capture a stop is terminal (1.03 rows per `agent_id`) and 94% of refused subagents send no stop; clearing is self-healing because a surviving subagent re-stamps within seconds, while a false "working" would outlive the work by the freshness window. The result is a stamp signal and not a count, because `SubagentStart` is younger than `SubagentStop` and a counter would run negative.
**Approved**: pending

**Decision**: `setsTurnState` checks `agent_id` only in its default branch, so a subagent's waiting `Notification` or `SessionStart` is counted.
**Rationale**: Open question: the code does not read `agent_id` for `Notification` or `SessionStart`, so a subagent's waiting `Notification` or non-compact `SessionStart` returns true, but the doc comment says "nor anything a subagent did" and the source gives no reason either way. The behavior is not required of ports until the owner decides, and no conformance vector pins it.
**Approved**: pending

**Decision**: `tableName` is derived from the raw value by a small loop, not stored per case.
**Rationale**: A new case gets its table name without a second edit; the cost is the consecutive-capitals behaviour noted in Edge Cases, accepted as a known limitation: `MCPCall` would become `m_c_p_call_events`.
**Approved**: pending

