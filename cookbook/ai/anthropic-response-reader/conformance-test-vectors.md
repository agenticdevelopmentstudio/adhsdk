
Vectors 001 to 005 come from `AnthropicResponseReaderTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| anthropic-response-reader-001 | chunking-independence, sse-message-start, sse-message-delta, usage-last-write-wins (`testSSESplitAtEveryByte`) | A streaming reader fed a stream with `message_start` (model "claude-x"; usage input 25, cache read 10, cache creation 5, output 1), a `content_block_delta`, a `message_delta` (stop reason "end_turn", output 42) and `message_stop`, one byte per `consume`, then `finish` | model "claude-x", input 25, output 42, cache read 10, cache creation 5, stop reason "end_turn" |
| anthropic-response-reader-002 | sse-line-framing (`testSSEWholeAndCRLF`) | The same stream with every line feed replaced by a carriage return and line feed, fed in one chunk, then `finish` | output 42 and model "claude-x" |
| anthropic-response-reader-003 | json-buffering, json-parse-at-finish, usage-keys (`testJSONMessage`) | A non-streaming reader fed `{"model":"claude-y","stop_reason":"tool_use","usage":{"input_tokens":3,"output_tokens":9,"cache_read_input_tokens":2,"cache_creation_input_tokens":1}}` split after 20 bytes, then `finish` | model "claude-y", stop reason "tool_use", input 3, output 9, cache read 2, cache creation 1 |
| anthropic-response-reader-004 | never-throws, sse-payload-object, sse-data-lines-only, json-parse-at-finish (`testGarbageStaysNil`) | For both modes: bytes 0xFF 0xFE 0x00 0x0A 0x7B, then `data: {broken`, a blank line and `data: [1,2]`, then `finish` | No error; model, input tokens, output tokens and stop reason are all nil |
| anthropic-response-reader-005 | json-size-limit (`testJSONOver4MiBStaysNil`) | Non-streaming: `{"model":"m","pad":"`, then 4 MiB of the letter a, then `"}`, then `finish` | model and output tokens are nil |
| anthropic-response-reader-006 | sse-final-line-flush | Streaming: feed `data: {"type":"message_delta","delta":{"stop_reason":"max_tokens"}}` with no trailing newline, then `finish` | stop reason "max_tokens" |
| anthropic-response-reader-007 | sse-data-prefix | Streaming: feed `data:{"type":"message_start","message":{"model":"m"}}` followed by a line feed (no space after the colon) | model "m" |
| anthropic-response-reader-008 | sse-other-events-ignored | Streaming: feed a `content_block_delta` event and a `ping` event carrying a `usage` object | Every field stays nil |
| anthropic-response-reader-009 | usage-last-write-wins | Streaming: a `message_start` with output 1, then a `message_delta` whose usage holds only `input_tokens` 9 | output stays 1, input is 9 |
| anthropic-response-reader-010 | sse-unterminated-line-cap | Streaming: feed 4 MiB plus 1 byte with no line feed, then a valid complete `message_start` line | The oversized prefix is discarded; the following line is read and sets its fields |
| anthropic-response-reader-011 | usage-keys | Non-streaming: `{"usage":{"input_tokens":"3"}}` | input tokens nil, because the value is text, not an integer |

