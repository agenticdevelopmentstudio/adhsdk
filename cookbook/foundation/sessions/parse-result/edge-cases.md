
- **Empty or whitespace-only file** (MUST): `.lostEvent`, never `.unparseable`, so the retry budget is not burned on a file that can never parse and the error badge does not stay lit.
- **Malformed JSON** (MUST): `.unparseable`, a real error the caller quarantines.
- **Wrong-typed fields** (MUST): `event`, `timestamp`, `account_email`, `oauth_account_email` and `session_id` of a non-string type are treated as missing; `hook_data` and `context` of a non-object type are treated as missing; a JSON `null` for any of them counts as missing too (**json-null-is-absent**). No field type raises an error by itself.
- **Missing `session_id`** (MUST): `.skip`, with a fixed reason string; never quarantined, because every retry would re-parse to the same skip.
- **Boundary: both event and session missing** (MUST): `.unparseable`, by the check order.
- **Valid JSON, trailing garbage** (MUST): `.unparseable`, because the whole text must parse as one JSON object.
- **Concurrent calls** (MUST): safe, the function holds no state.
- **Cancellation, timeouts** (not applicable): the function is synchronous and does no I/O.
- **Error states, offline or disconnected** (not applicable): the input is already a `String` in memory; reading the file, and what to do when it cannot be read, belong to the caller.

