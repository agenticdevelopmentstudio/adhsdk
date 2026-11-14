
### Errors

- **translation-error-cases**: `TranslationError` MUST have exactly three cases, `notAnObject`, `noMessages` and `malformedReply`, and MUST be `Equatable`.
- **only-structural-failure-throws**: Only `chatRequest` and `anthropicMessage` MAY throw, and only with a `TranslationError` for structural failure; `anthropicError` and the stream translator MUST NOT throw.

### Request translation (`chatRequest`)

- **request-not-object**: `chatRequest` MUST throw `notAnObject` when the body does not parse as a JSON object (invalid JSON, or a top-level array or scalar).
- **request-no-messages**: `chatRequest` MUST throw `noMessages` when `messages` is missing, is not an array of objects (a single non-object element makes the whole cast fail), or is empty.
- **request-model**: The output MUST set `model` to the `model` argument; the request's own `model` field is not read.
- **request-system-prompt**: When `system` is a string, or an array whose text blocks join to a non-empty string, the output MUST begin its `messages` with one `system` message holding that text; an absent, non-string-or-array or empty system prompt MUST produce no system message.
- **request-text-join**: Text blocks of an array MUST be joined with two line feeds between them; non-text blocks contribute nothing, and an `image` block in a system prompt is dropped.
- **request-role-routing**: A message with role `assistant` MUST become one assistant message; any other role, and a missing role (treated as `user`), MUST be treated as a user message.
- **request-user-string**: A user message whose content is a string MUST become one user message with that string.
- **request-user-nonlist**: A user message whose content is neither a string nor an array of objects MUST become one user message with empty content.
- **request-user-text-only**: A user message of blocks with text and no image MUST become one user message whose content is the text blocks joined by two line feeds.
- **request-user-image-parts**: A user message that holds at least one convertible image MUST become one user message whose content is a part list in block order, with `text` parts and `image_url` parts.
- **request-image-base64**: A `base64` image source with text `media_type` and `data` MUST become the URL `data:<media_type>;base64,<data>`.
- **request-image-url**: A `url` image source MUST become that URL; an image block with no `source`, an unknown source type, or missing fields MUST be dropped.
- **request-tool-result**: Each `tool_result` block MUST become a `tool` message with `tool_call_id` from `tool_use_id` (empty string when absent) and content from the block's content (text blocks joined by two line feeds, with an image inside a tool result replaced by the text `[image omitted]`).
- **request-tool-result-error**: A `tool_result` with `is_error` equal to true MUST have its content prefixed with `Error: `.
- **request-tool-message-order**: In a user message, all `tool` messages MUST come before the user text or parts message, in block order.
- **request-user-empty-fallback**: A user message whose blocks yield no parts and no tool messages MUST become one user message with empty content.
- **request-assistant-string**: An assistant message whose content is a string MUST become an assistant message with that string and no `tool_calls`.
- **request-assistant-blocks**: An assistant message whose content is a block array MUST become one assistant message whose content is its text blocks joined by two line feeds (empty string when there are none) and whose `tool_calls` carry one entry per `tool_use` block.
- **request-assistant-null-content**: An assistant message with `tool_use` blocks and no text MUST have content set to JSON null; with neither text nor tool use it MUST have empty-string content.
- **request-tool-call-shape**: Each tool call MUST have `id` from the block (empty string when absent), `type` `function`, and a `function` object with `name` (empty string when absent) and `arguments` holding the block's `input` serialized as JSON text, `{}` when `input` is absent or cannot be serialized.
- **request-unknown-blocks-dropped**: Blocks of any other type (`thinking`, `redacted_thinking`, unknown) MUST be dropped, and `cache_control` MUST NOT reach the output.
- **request-tools**: Each Anthropic tool with both a `name` and an `input_schema` MUST become `{"type":"function","function":{name, description (when text), parameters: input_schema}}`; a tool missing either (such as a typed server tool like web search) MUST be dropped, and `tools` MUST be omitted when none remain.
- **request-tool-choice**: `tool_choice` with type `auto` MUST map to `auto`, `any` to `required`, `none` to `none`, and `tool` with a `name` to `{"type":"function","function":{"name":...}}`; a `tool` choice with no name, or an unknown type, MUST produce no `tool_choice`.
- **request-tool-choice-independent**: `tool_choice` MUST be translated whether or not any tool survived conversion.
- **request-pass-through-fields**: `stop_sequences` MUST be copied as `stop`, and `temperature` and `top_p` copied under the same names, whatever their value; `top_k`, `metadata` and `thinking` MUST be dropped.
- **request-max-tokens-key**: `max_tokens` MUST be copied under the name given by `maxTokensKey` (default `max_tokens`) only when the request has it; the translator MUST NOT add a default value.
- **request-stream**: When `stream` is the boolean true the output MUST set `stream` true and `stream_options` to `{"include_usage":true}`; otherwise neither key MUST appear.

### Non-streamed reply (`anthropicMessage`)

- **reply-malformed**: `anthropicMessage` MUST throw `malformedReply` when the body is not a JSON object, has no first `choices` element, or that element has no `message` object.
- **reply-envelope**: The output MUST have `type` `message`, `role` `assistant`, and `stop_sequence` null.
- **reply-id**: The output `id` MUST be `msg_` followed by the reply's `id` when it is text, otherwise `msg_` followed by a UUID with its hyphens removed.
- **reply-model**: The output `model` MUST be the reply's `model` when it is a non-empty string, otherwise the `fallbackModel` argument.
- **reply-text-block**: A non-empty string `message.content` MUST become one leading `text` block; empty or null content MUST add no text block.
- **reply-tool-blocks**: Each entry of `message.tool_calls` MUST become a `tool_use` block with `id` (the call's id, or `toolu_` followed by a UUID with hyphens removed when absent), `name` (empty string when absent) and `input`.
- **reply-tool-input**: `input` MUST be the parsed `arguments` text when it parses as a JSON object, and an empty object otherwise (unparseable text, a non-object value, or missing arguments).
- **reply-usage**: `usage` MUST hold `input_tokens` from `prompt_tokens` and `output_tokens` from `completion_tokens`, each 0 when absent or not an integer; cache token counts are not produced.
- **reply-only-first-choice**: Only the first element of `choices` MUST be read.

### Stop reason mapping

- **stop-reason-map**: A finish reason MUST map `stop` to `end_turn`, `length` to `max_tokens`, `tool_calls` and `function_call` to `tool_use`, `content_filter` to `refusal`, and anything else, including null, to `end_turn`.

### Error translation (`anthropicError`)

- **error-never-throws**: `anthropicError` MUST return Anthropic error JSON of shape `{"type":"error","error":{"type":...,"message":...}}`.
- **error-message-source**: For a body that parses as a JSON object, the message MUST come from exactly one place chosen by the shape of `error`: `error.message` when `error` is an object, `error` itself when it is a string, and top-level `message` only when `error` is neither (an `error` object with no text `message` does not fall through to the top-level `message`); when the chosen place holds no text, or the body is not a JSON object, the message MUST be the first 500 characters of the body decoded as UTF-8 (empty when the body is empty or not UTF-8).
- **error-type-map**: The error type MUST map status 400 to `invalid_request_error`, 401 to `authentication_error`, 403 to `permission_error`, 404 to `not_found_error`, 413 to `request_too_large`, 429 to `rate_limit_error`, 529 to `overloaded_error`, and every other status to `api_error`.
- **error-serialization-fallback**: If the result cannot be serialized, `anthropicError` returns empty data; the source falls back with a failed-serialization default and no signal. Because the object holds only strings, no input is known to reach that path.

### Stream translator (`ChatCompletionsStreamTranslator`)

- **stream-init**: `init(model:messageID:)` MUST take the model name for `message_start` and a message id defaulting to `msg_` followed by a hyphenless UUID.
- **stream-consume-contract**: `consume(_:)` MUST accept Chat Completions server-sent-event bytes in chunks of any size and return the Anthropic event bytes ready to send, which can be empty.
- **stream-line-framing**: The translator MUST buffer input, process each complete line ending in a line feed, and strip one trailing carriage return, so output is identical whether the input is fed whole or one byte at a time (compared as parsed events; JSON key order is not fixed).
- **stream-data-lines-only**: A line MUST be used only if it decodes as UTF-8 and starts with `data:`, with one optional space after the colon; other lines, and `data:` lines whose payload is not a JSON object, MUST be ignored.
- **stream-event-format**: Each output event MUST be the text `event: <name>` and a line feed, `data: <json>` and two line feeds.
- **stream-message-start**: `message_start` MUST be emitted once, before the first translated content, at the first parsed JSON object that is not an error, even one with no `choices`, with id, `model`, role `assistant`, empty `content`, null stop fields and zero usage.
- **stream-text-delta**: A non-empty `delta.content` string MUST open a `text` content block when no text block is open (closing an open tool block first) and emit a `text_delta`; empty content MUST emit nothing.
- **stream-single-open-block**: At most one content block MUST be open at any time; every block start follows the previous block's stop, and block indexes increase from 0.
- **stream-tool-key**: A tool-call fragment MUST be keyed by its `index` when present; without an index, a fragment MUST continue the most recent keyless call when it has no id, an empty id, or that call's id, and MUST otherwise start a new call (including the first keyless fragment, and a new id arriving while the current call has no id).
- **stream-tool-start**: A tool block MUST start only once the call has a name; fragments before then MUST accumulate their `arguments` text, which is flushed in the first `input_json_delta` after the start.
- **stream-tool-name-capture**: A call's name MUST be taken from the first fragment that carries a `name` while the block has not started and no name is set; later names MUST be ignored.
- **stream-tool-id**: The `tool_use` block id MUST be the provider's id, or `toolu_` followed by a hyphenless UUID when none arrived.
- **stream-tool-arguments**: Each non-empty `arguments` fragment for an open tool block MUST be emitted as an `input_json_delta` with `partial_json` equal to the fragment, with no validation.
- **stream-tool-after-close**: A fragment for a tool call whose block has already closed MUST be dropped; a block closes when later text or another tool block starts, or at the end.
- **stream-first-choice-only**: Only the first element of `choices` MUST be read.
- **stream-usage**: `prompt_tokens` and `completion_tokens` from a `usage` object MUST be remembered (last integer wins) and reported at the end.
- **stream-finish-reason**: A `finish_reason` string MUST set the stop reason by the stop-reason mapping; a stream with none MUST end with `end_turn`.
- **stream-done**: The line `data: [DONE]` MUST discard the remaining buffer and end the stream as `finish` does; nothing after it MAY be processed, including lines in the same chunk.
- **stream-finish**: `finish()` MUST process a final unterminated line, then (if not already finished) emit `message_start` if none was sent, start any pending named tool call that never started (in descending key order), close the open block, then emit one `message_delta` and one `message_stop`.
- **stream-finish-pending-unnamed**: A pending tool call that never received a name MUST be dropped at the end with its arguments.
- **stream-message-delta**: `message_delta` MUST carry `delta.stop_reason`, a null `stop_sequence`, and usage with both `output_tokens` and `input_tokens` (0 when never reported).
- **stream-finish-idempotent**: After the stream has finished, `consume` and `finish` MUST return empty data, so closing events are sent once.
- **stream-error-event**: A parsed object holding `error` as an object MUST end the stream: close the open block, emit one `error` event of type `api_error` with the provider's message (or `provider stream error` when it is not text), and emit no `message_delta` or `message_stop`; later input is ignored. No `message_start` is emitted if the error is the first object.
- **stream-single-threaded**: The translator is a non-`Sendable` class documented "Not thread-safe; one per response; never crosses an isolation boundary", so each instance MUST serve one response on one thread or task at a time.
- **stream-no-idempotency-or-retry**: Each translation call is a pure transformation; the component sends no request, so retries, idempotency keys, timeouts and backoff belong to the caller.

