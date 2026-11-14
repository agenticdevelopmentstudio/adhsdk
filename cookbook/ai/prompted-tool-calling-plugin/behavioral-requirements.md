
Wrapping

- **wrap-plugin**: The initializer `init(wrapping:)` MUST keep the plugin it is given and forward to it everything this type does not change.
- **wrap-nothing-fails**: The required parameterless initializer, which exists because the plugin contract demands it for loading a principal class from a bundle, MUST wrap a plugin that makes every request fail with the error description "PromptedToolCallingPlugin was created without a plugin to wrap." and whose decoder yields no events.
- **forward-validation**: `buildValidationRequest(config:)` MUST return the wrapped plugin's value unchanged.
- **forward-error-description**: `describeError(status:body:)` MUST return the wrapped plugin's value unchanged.

Building the request

- **build-no-tools-passthrough**: When the context's tools list is empty, `buildRequest` MUST hand the context to the wrapped plugin unchanged and return its request.
- **build-tools-into-prompt**: When the context has tools, `buildRequest` MUST pass the wrapped plugin a context whose system prompt is the original system prompt (when present and non-empty) followed by a blank line and the tool instructions.
- **build-empty-prompt-omitted**: A nil or empty original system prompt MUST be left out, so the instructions are the whole prompt without a leading separator.
- **build-tools-emptied**: The wrapped plugin's context MUST carry an empty tools list, since the tools are described in the prompt and the wrapped plugin's own tool handling is not used.
- **build-builtins-off**: The wrapped plugin's context config MUST set the built-in-tools key (`AIPluginConfig.builtInToolsKey`, `builtInTools`) to `none`, because the described tools are the only ones this turn may use.
- **build-keeps-other-fields**: The model, the maximum tokens and the rest of the config MUST pass through unchanged.
- **build-history-as-text**: The wrapped plugin's messages MUST be the conversation rewritten by the textual history rule below.
- **build-errors-propagate**: An error thrown by the wrapped plugin's `buildRequest` MUST propagate.

Tool instructions

- **instructions-catalog**: The instructions MUST begin `You can call these tools:` and list each tool as `- <name>: <description>` followed on the next line by two spaces and `Arguments (JSON Schema): <schema>`, where the schema is the tool's schema data as UTF-8 text, or `{}` when it cannot be read as text.
- **instructions-protocol**: The instructions MUST tell the model that the tools are not native functions, that writing the block is the only way to call them, and that it must never answer as if a call had been made when it has not.
- **instructions-block-format**: The instructions MUST show the block as `<tool_call>{"name": "<tool name>", "arguments": {<arguments as JSON>}}</tool_call>`, on its own lines with nothing after it.
- **instructions-stop-and-wait**: The instructions MUST tell the model to stop and wait, that the result returns in the next message marked as a tool result, to call only listed tools with one block per call, to answer in plain text with no blocks when it needs no more calls, and never to invent a tool result.

Textual history

- **history-passthrough**: Messages whose role is neither a tool use nor a tool result MUST be copied unchanged, in order.
- **history-call-block**: A tool-use message MUST become the block `<tool_call>{"name": <name as JSON string>, "arguments": <arguments JSON>}</tool_call>`, with an absent name taken as the empty string and absent arguments as `{}`.
- **history-call-joins-assistant**: A tool-use block MUST be appended, after a newline, to the immediately preceding message when that message is from the assistant; otherwise it MUST become a new assistant message.
- **history-result-label**: A tool-result message MUST become the text `[Tool result]` (or `[Tool error]` when the result is marked as an error) on one line, followed by a newline and the result content.
- **history-result-joins-user**: A tool-result text MUST be appended, after a blank line, to the immediately preceding message when that message is from the user; otherwise it MUST become a new user message.

Parsing a reply

- **parse-lift-blocks**: Parsing a finished reply MUST remove each complete `<tool_call>...</tool_call>` pair whose body is a JSON object with a non-empty string `name`, and return it as a call with that name and the object's `arguments` re-encoded as JSON.
- **parse-missing-arguments**: A block whose object has no `arguments` MUST yield arguments `{}`.
- **parse-malformed-kept**: A pair whose body is not a JSON object, or whose `name` is missing, not a string or empty, MUST stay in the prose exactly as written, so the user sees what the model wrote.
- **parse-unclosed-kept**: An opening tag with no closing tag after it MUST leave the rest of the reply from the open tag onward in the prose.
- **parse-order**: Prose and calls MUST come out in the order they appeared: calls in reply order, prose segments concatenated.
- **parse-trim**: The prose MUST have leading and trailing whitespace and newlines removed.

Decoding

- **decode-wraps-decoder**: `makeDecoder()` MUST return a decoder around the wrapped plugin's own decoder.
- **decode-hold-text**: The decoder MUST NOT emit any text delta from the wrapped decoder while the reply is in progress; it MUST accumulate the text and emit nothing.
- **decode-flush-at-end**: When the wrapped decoder reports the end of the reply, the decoder MUST parse the accumulated text and emit, in order: one text delta for the prose when non-empty, one tool-use event per call, then one end event.
- **decode-call-ids**: Call ids MUST be `prompted-1`, `prompted-2` and so on, in order, per decoder.
- **decode-stop-reason**: The end event's stop reason MUST be `tool_use` when at least one call was lifted, and otherwise the wrapped decoder's stop reason.
- **decode-native-tool-use-passes**: A tool-use event from the wrapped decoder (a provider that does call tools natively) MUST pass through immediately.
- **decode-finish-flushes**: `finish()` MUST absorb the wrapped decoder's final events and, if the reply has not been flushed (the wrapped decoder never reported an end), flush it with no stop reason.
- **decode-flush-once**: The decoder MUST flush at most once; an end event after a flush is dropped.
- **decode-no-tools-still-buffers**: NEEDS REVIEW: Not implemented in source. The type's doc comment says a context with no tools passes through untouched, and `buildRequest` honours that, but `makeDecoder()` takes no context, so it always buffers the reply and lifts `<tool_call>` blocks even when the request carried no tools. A decision on whether the decoder should be told when no tools were sent (and so pass text through as it streams) would settle it.

