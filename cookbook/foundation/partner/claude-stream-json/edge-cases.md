
- **Empty and null input**: An empty line throws "not JSON". A JSON `null`, number or string at the top level is not an object; the parser throws the "not JSON" error for a scalar top level because fragments are not allowed, so such a line is rejected either way.
- **Array top level**: A line that is a JSON array throws "not a JSON object".
- **Malformed input**: Truncated JSON throws "not JSON". The caller (the process reader) decides what to do with a throw; this decoder does not log or recover.
- **Wrong field types**: A key present with the wrong type (a numeric `session_id`, a string `is_error`, a non-integer `num_turns`) reads as absent, with `isError` falling back to `false`; no error is raised.
- **Mixed `message.content` array**: If `content` is an array that contains any non-object element, the array does not read as an array of objects and `blocks` stays empty rather than being partly filled.
- **Unknown block type**: Becomes a `.other` block, so a new claude block type never breaks decoding.
- **Unknown message type**: Becomes `.other(type)`, so a new stream event type never breaks decoding.
- **Lost session wording**: `reportsLostSession` is a substring match on `"No conversation found"`; a claude release that rewords that message stops it matching, and an error whose text merely contains the phrase matches.
- **Non-error result mentioning the phrase**: A result with `is_error` false never reports a lost session, whatever its text.
- **Concurrent access**: Every type is a `Sendable` value and both entry points are pure static functions with no shared state, so any number of lines can be decoded in parallel.
- **Cancellation, timeouts and offline state**: Not applicable: decoding is synchronous on in-memory data and performs no I/O; the pipe to claude belongs to the process owner.
- **Very large lines**: There is no size limit; the whole line is parsed in memory.

