
- **No registrations**: `tools/list` MUST return an empty list, and any `tools/call` MUST return `unknown tool <name>`.
- **Source with no tools**: MUST contribute nothing to the listing and never match a call.
- **Empty or missing arguments**: MUST be sent to the source as `{}`.
- **Tool name equal to a prefix**: a name that equals a registration's prefix leaves an empty bare name, which matches only a source that advertises an empty name; otherwise the next registration is tried.
- **Empty prefix and overlapping prefixes**: the empty prefix matches every name, so registration order decides; earlier registrations win.
- **Name advertised by two sources**: the first registered source is called; the second is unreachable by that name.
- **Source throws or returns an error**: sources return a content string and an error flag and cannot throw through the contract; an error flag becomes an MCP error result, and no later registration is tried.
- **Schema bytes that do not decode**: MUST fall back to an empty object schema; the failure is not logged.
- **Concurrent calls**: the actor serialises its own state, but `tools/call` handlers run in separate tasks in the SDK and each awaits the source, so two calls to a slow source can overlap; the server adds no lock around source calls.
- **Overlapping `serve` or `stop`**: see the open question on `serve-reentrancy`.
- **Transport closes**: the message loop ends and `waitUntilServerCompleted()` returns; the server stays recorded as current until `stop()` is called.
- **Stateless HTTP caller**: a `tools/call` with no `initialize` MUST be answered.
- **Unreachable client or network loss mid-call**: the source call continues to completion and the reply is written to the transport; the server has no retry, timeout or cancellation of its own.
- **Caller header absent**: the caller MUST be nil, and sources that ignore it are unaffected.

