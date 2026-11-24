
- **Unknown event type** (MUST): `isActivity` and `setsTurnState` treat a string outside the enum as activity, and `setsTurnState` falls to the `agent_id` rule; the enum has no failure path for it.
- **Empty string** (MUST): `isActivity("")` is true and `setsTurnState("", [:])` is true.
- **Missing or wrong-typed `hook_data` fields** (MUST): `notification_type`, `source` and `agent_id` of another type than string are treated as absent; an empty `agent_id` is treated as absent.
- **Boundary: stop without start** (MUST): `subagentClock` returns -1 for `SubagentStop` with no earlier `SubagentStart`, because most subagents on disk have a stop and no start.
- **Table name for consecutive capitals** (MUST, **table-name**): `tableName` puts `_` before each uppercase character, so a future event name such as `MCPCall` MUST become `m_c_p_call_events`; this is an accepted limitation, and no current case has consecutive capitals.
- **Concurrent access** (MUST): every member is immutable or pure, so concurrent calls need no coordination.
- **Error states, offline or disconnected** (not applicable): no function does I/O, throws or touches a network.
- **Case sensitivity** (MUST): raw values are compared exactly; `Stop` and `stop` differ.

