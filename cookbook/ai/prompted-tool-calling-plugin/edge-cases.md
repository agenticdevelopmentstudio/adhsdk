
- **Null and empty input**: A nil or empty system prompt is omitted from the joined prompt (MUST). An empty reply flushes to just an end event (MUST). A tool with an unreadable schema is described with `{}` (MUST).
- **Boundary values**: A reply that is only a valid block yields no text event, one tool use and a `tool_use` end (MUST). A block with an empty `name` is malformed and stays in the prose (MUST).
- **Malformed blocks**: Invalid JSON, a non-object body, a missing or non-string name all leave the block in the prose (MUST). An unclosed open tag keeps everything from it onward as prose, and stops further parsing of the remainder (MUST).
- **Concurrent access**: The plugin is stateless and marked unchecked sendable; each decoder holds mutable state and is for one reply on one task, so a decoder MUST NOT be shared between replies (MUST NOT).
- **Error states**: An error from the wrapped plugin's request building propagates (MUST). A wrapped decoder that never reports an end still flushes at `finish()` (MUST). A `finish()` after a flush adds nothing from the reply (MUST).
- **Non-object arguments**: A block whose `arguments` is present but not an object (a string, number or null) is still lifted; the value is re-encoded as a JSON fragment and passed on as the call's arguments, with no check that it is an object (MUST, per `parse-lift-blocks`).
- **Text after the flush**: Text deltas that reach the decoder after it has flushed are accumulated and never emitted, because only the first end event or `finish()` flushes (MUST, per `decode-flush-once`).
- **Consecutive tool messages in history**: Several tool-use messages in a row each join the preceding assistant message, and several results join the preceding user message, so history stays alternating (MUST, per the join rules).
- **A text reply with a native tool use**: Native tool uses pass through immediately while the text is still held (MUST).
- **Call ids restart per decoder**: Ids are numbered per decoder, so two turns can both produce `prompted-1`; the source does not address uniqueness across turns.
- **Offline or disconnected state**: Not applicable — the type builds requests and decodes bytes and does no I/O itself.
- **Cancellation and timeouts**: Not applicable — it has no asynchronous work; the held-back reply is lost if the stream is abandoned before the end.

