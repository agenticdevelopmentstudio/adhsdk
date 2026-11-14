
`SessionStatus` is the lifecycle state of a Claude Code session: `active`, `stale` or `ended`. It answers only whether a process exists for the session. What a live session is doing is a separate question, answered by `SessionActivity`.

The enum is a `String`-backed value. The raw strings are what the SDK writes to the sessions table's status column, compares against rows read back, and publishes in the `{session_id, status}` payload that `SessionEventEncoding.encodeSessionStatus(sessionId:status:)` builds. A port has to keep those three strings exactly.

