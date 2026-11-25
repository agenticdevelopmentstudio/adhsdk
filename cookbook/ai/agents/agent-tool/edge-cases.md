
- **Empty tool list**: A reply of `[]` yields an empty array from `load()` (MUST); no error is thrown.
- **Missing schema**: A tool with no `input_schema` yields `{}` (MUST).
- **Unknown permission string**: Yields `auto`, the most permissive value, with no error (MUST, as written in `remote-permission-default`; a known hazard, see Design Decisions).
- **Invalid argument JSON**: `run` throws `invalidArguments` and posts nothing; empty arguments are posted as `{}` (`remote-arguments-fallback`).
- **Arguments that are valid JSON but not an object** (an array, string or number): `run` throws `invalidArguments(tool:)` and posts nothing (`remote-arguments-fallback`).
- **List reply array mixing objects and other values**: `load()` throws `malformedReply("Expected a JSON array of tools")`; it does not skip the other elements (MUST, `remote-array-required`).
- **Non-JSON 200 body from the list**: `JSONSerialization` throws its own error, not a `RemoteAgentToolError`; that error propagates (MUST).
- **Non-2xx with an undecodable body**: The message falls back to the body's UTF-8 text, then to an empty string (MUST).
- **Unknown tool name at call time**: The host answers 404 and the client throws `failed(status: 404, ...)`; the client does not refresh its tool list (MUST).
- **Transport unreachable or cancelled**: The transport's error propagates out, and `run` makes no cancellation check of its own (`remote-cancellation`); there is no timeout, retry, backoff or reconnection in this code, and the owner of those is the transport the caller supplies (MUST propagate, SHOULD be handled by the caller).
- **Tool list changes after load**: A loaded tool is a snapshot; changes on the host are seen only by calling `load()` again (MUST NOT be assumed live).
- **Duplicate tool names in a reply**: Both entries are returned in order; this code does not deduplicate.
- **Concurrent calls**: Not serialised; the code is stateless, and any ordering rule belongs to the host.
- **Offline**: Not applicable beyond the transport error above; the client keeps no cache and has no offline mode.

