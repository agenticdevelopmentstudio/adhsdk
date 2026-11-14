
- **Empty or missing input**: an empty body MUST throw `notAnObject`; empty `messages` MUST throw `noMessages`; an empty `choices` array MUST throw `malformedReply` (MUST).
- **Unknown block types**: MUST be dropped silently, never an error (MUST).
- **Unknown or absent `tool_choice` type**: MUST produce no `tool_choice` (MUST).
- **Tool input that is not an object**: a non-object `input` in a request is serialized as JSON text as given (fragments allowed); in a reply, non-object `arguments` become an empty input object (MUST).
- **Reply tool arguments that are invalid JSON**: replaced by an empty input object with no signal; the loss is deliberate and tested (MUST).
- **Stream tool arguments that are invalid JSON**: forwarded unchanged as `partial_json`; the receiver sees the invalid text (MUST).
- **Provider sends text after a tool call began**: the tool block closes and a new text block opens; fragments for the closed tool call are dropped (MUST).
- **Interleaved parallel tool calls**: output keeps one open block, so interleaved arguments of an earlier call can be lost; the translator accepts that cost over sending invalid Anthropic events (MUST).
- **Stream ends without `[DONE]`**: the caller's `finish` produces the closing events (MUST).
- **Stream cut mid-line**: `finish` processes the partial line, which parses only if complete JSON (MUST).
- **Provider error in the stream**: `error` event only, with no `message_stop` (MUST).
- **Provider HTTP error**: use `anthropicError` with the status and body; a body with no text message in the place its shape selects (including a non-JSON body) is truncated to 500 characters (MUST).
- **Multiple choices**: only the first is used in replies and streams (MUST).
- **Concurrent access**: the static functions are pure and may run in parallel; a translator instance is not thread-safe and is confined to one response by its own documentation, so the question of two calls interleaving does not arise (MUST).
- **Offline or disconnected state**: Not applicable — the component only transforms bytes it is handed; an interrupted upstream shows up as a stream that ends early.
- **Cancellation and timeouts**: Not applicable — every operation is synchronous; the component declares no timeout or cancellation hook.
- **Large bodies**: the stream buffer has no cap and the request path has no size limit; whole bodies live in memory (MUST NOT be assumed bounded).

