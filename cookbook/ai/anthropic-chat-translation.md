---
id: b6cceff2-b2d0-44a9-ac82-4d900486bab6
title: "Anthropic Chat Translation"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wire translation between the Anthropic Messages API and OpenAI Chat Completions: request, whole reply, error body, and a streaming translator."
platforms:
  - swift
  - macos
tags:
  - ai-plugin
  - anthropic
  - openai-compatible
  - wire-translation
  - streaming
depends-on: []
related:
  - 4d7ed9a3-c6d8-491b-911a-cf257fde1c38
references: []
approved-by: ""
approved-date: ""
---

# Anthropic Chat Translation

## Overview

This component lets a client that speaks the Anthropic Messages API talk to a provider that speaks OpenAI Chat Completions. It has two parts. `AnthropicChatTranslation` is a caseless enumeration of static functions: `chatRequest(fromMessages:model:maxTokensKey:)` turns an Anthropic request body into a Chat Completions request body, `anthropicMessage(fromChatCompletion:fallbackModel:)` turns a whole Chat Completions reply into an Anthropic `message`, and `anthropicError(status:body:)` turns a provider error body into an Anthropic error. `ChatCompletionsStreamTranslator` is a stateful class that takes Chat Completions server-sent-event bytes in and returns Anthropic server-sent-event bytes out. Per the source's doc comment: "Pass-through dictionaries via `JSONSerialization`; only structural failure throws, unknown content blocks are dropped." The component makes no network call, holds no credential and writes no file. Translation is lossy by design: thinking blocks, cache controls, metadata and similar Anthropic-only fields are dropped.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a wire-format translator, not a visual component.

## States

Not applicable — this is a wire-format translator, not a visual component. The stream translator's runtime state (before start, started, finished, failed) is described under Behavioral Requirements.

## Accessibility

Not applicable — this is a wire-format translator, not a visual component.

## Conformance Test Vectors

Vectors are derived from `AnthropicChatTranslationTests` unless noted.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| anthropic-chat-translation-001 | request-model, request-system-prompt (`testSystemStringAndUserString`) | `{"system":"be brief","messages":[{"role":"user","content":"hi"}]}`, model "gpt-x" | `model` "gpt-x"; messages are a system message "be brief" then a user message "hi" |
| anthropic-chat-translation-002 | request-text-join, request-unknown-blocks-dropped (`testSystemBlocksJoinedAndCacheControlDropped`) | System as two text blocks "one" and "two" carrying `cache_control`, and a user text block with `cache_control` | System message "one", two line feeds, "two"; user message "hi"; the output text has no `cache_control` |
| anthropic-chat-translation-003 | request-assistant-blocks, request-tool-call-shape (`testAssistantTextAndTwoToolUses`) | Assistant blocks: text "working", `tool_use` t1 "a" with input x=1, `tool_use` t2 "b" with empty input | Content "working"; two calls; first has id t1, type function, name "a", arguments parsing to x=1; second arguments `{}` |
| anthropic-chat-translation-004 | request-assistant-null-content, request-assistant-blocks (`testAssistantWithoutTextHasNullContent`, `testEmptyAssistantMessageHasEmptyContent`) | An assistant message with only a `tool_use` block; then one with only a `thinking` block; then one with an empty array | Content null; then empty string; then empty string |
| anthropic-chat-translation-005 | request-tool-result, request-tool-message-order, request-tool-result-error (`testToolResultsBecomeToolMessagesBeforeUserText`) | User blocks: text "after", `tool_result` t1 "ok", `tool_result` t2 with `is_error` true and text block "boom" | Messages: tool t1 "ok", tool t2 "Error: boom", then user "after" |
| anthropic-chat-translation-006 | request-tool-result (`testToolResultWithBlockArrayAndImage`) | `tool_result` t1 holding text "one", a base64 image, text "two" | One tool message with content "one", two line feeds, `[image omitted]`, two line feeds, "two" |
| anthropic-chat-translation-007 | request-image-base64, request-image-url, request-user-image-parts (`testBase64AndURLImages`) | User blocks: base64 png "AAAA", url "https://x/y.png", text "what?" | One user message with parts: `image_url` `data:image/png;base64,AAAA`, `image_url` `https://x/y.png`, `text` "what?" |
| anthropic-chat-translation-008 | request-tools, request-tool-choice (`testToolsAndToolChoice`) | Tools: "a" with description and schema, and a typed `web_search_20250305` tool; `tool_choice` any; then auto, none, and tool named "a" | One function tool with name, description and parameters; `tool_choice` "required"; then "auto", "none", and a function-name object |
| anthropic-chat-translation-009 | request-stream (`testStreamAddsStreamOptions`) | `stream` true; then no `stream` | `stream` true with `stream_options` `{"include_usage":true}`; then neither key |
| anthropic-chat-translation-010 | request-max-tokens-key, request-pass-through-fields (`testMaxTokensKeyAndPassThroughFields`) | `max_tokens` 100, `temperature` 0.5, `top_p` 0.9, `stop_sequences` ["END"], `metadata`, `thinking`, `top_k`; key "max_completion_tokens" | `max_completion_tokens` 100, no `max_tokens`; temperature, `top_p` and `stop` copied; `metadata`, `thinking`, `top_k` absent |
| anthropic-chat-translation-011 | request-not-object, request-no-messages (`testStructuralFailuresThrow`) | Body `[1]`; body `nope`; body `{"messages":[]}` | `notAnObject`; `notAnObject`; `noMessages` |
| anthropic-chat-translation-012 | stream-line-framing, stream-message-start, stream-text-delta, stream-finish, stream-message-delta (`testStreamedTextByteAtATimeEqualsWhole`) | Chat stream: role chunk with empty content, "Hel", "lo", a chunk with `finish_reason` stop, a usage-only chunk (7 prompt, 3 completion), then `[DONE]`; fed whole and one byte at a time, id "msg_fixed", model "gpt-x" | Same parsed events both ways: `message_start`, `content_block_start`, two `content_block_delta`, `content_block_stop`, `message_delta` (stop `end_turn`, output 3, input 7), `message_stop` |
| anthropic-chat-translation-013 | stream-tool-key, stream-tool-start, stream-single-open-block (`testTextThenTwoToolCalls`) | Text "ok", then tool 0 (id c0, name alpha, args in three fragments) and tool 1 (id c1, name beta, two fragments), then `finish_reason` tool_calls | Block starts at indexes 0, 1, 2 of types text, tool_use, tool_use; joined fragments `{"a":1}` and `{"b":2}`; three stops; stop reason `tool_use`; last event `message_stop` |
| anthropic-chat-translation-014 | stream-tool-after-close (`testInterleavedToolFragmentsNeverOpenTwoBlocks`) | Tool 0 fragment, tool 1 complete, tool 0 continuation `1}`, then text "late" with `finish_reason` | Never two blocks open; the late `1}` fragment is dropped; fragments emitted are `{"a":` and `{"b":2}` |
| anthropic-chat-translation-015 | stream-tool-start, stream-tool-name-capture, stream-finish-pending-unnamed (`testToolBlockWaitsForNameNotJustID`, `testNamelessPendingCallDroppedAtFinish`) | A call with id and arguments but no name, then its name "alpha" later; then a call with id and arguments and never a name | Block starts with name "alpha", id c0, and one delta `{"a":1}` (arguments buffered until the name); the nameless call yields only `message_start`, `message_delta`, `message_stop` |
| anthropic-chat-translation-016 | stream-tool-key (`testKeylessIDStartsNewCallEvenWhenCurrentHasNoID`) | Keyless fragments: arguments with no id or name, then id k0 name alpha, then continuation, then id k1 name beta | Orphan dropped; blocks for alpha and beta in order; alpha's joined fragments `{"a":1}` |
| anthropic-chat-translation-017 | stream-tool-id (`testGeneratedToolUseID`) | One tool fragment with a name and no id | `tool_use` block id starts with `toolu_` and is longer than 6 characters |
| anthropic-chat-translation-018 | stream-done (`testLinesAfterDoneInSameChunkNeverProcessed`, `testDataAfterDoneIsIgnored`) | `data: [DONE]` followed in the same chunk by a content chunk; and a complete stream followed by more data | Only `message_start`, `message_delta`, `message_stop`; no later text appears; exactly one `message_stop` |
| anthropic-chat-translation-019 | stream-error-event (`testMidStreamErrorClosesBlockAndEmitsErrorOnly`) | Content "partial", then an `error` object with message "upstream died", then more content | Events: `message_start`, `content_block_start`, `content_block_delta`, `content_block_stop`, `error` with type `api_error` and message "upstream died"; and a bare `error` object alone yields only `error` with message `provider stream error` |
| anthropic-chat-translation-020 | stream-finish-idempotent (`testFinishTwiceEmitsClosingEventsOnce`) | A complete stream through `[DONE]`, then `finish` called twice | One `message_delta` and one `message_stop` |
| anthropic-chat-translation-021 | stop-reason-map (`testFinishReasonMapping`) | Stream finish reasons length, content_filter, function_call, weird | `max_tokens`, `refusal`, `tool_use`, `end_turn` |
| anthropic-chat-translation-022 | stream-line-framing (`testCRLFSplitAcrossChunks`, `testNonASCIITextFedOneByteAtATime`) | A `data:` line fed, then a lone carriage return, then a line feed; and text with accented letters, an emoji and Japanese fed one byte at a time | Events appear only after the line feed; multi-byte text arrives intact |
| anthropic-chat-translation-023 | reply-envelope, reply-id, reply-tool-input, reply-usage, stop-reason-map (`testNonStreamedReplyWithToolCalls`) | Reply id "chatcmpl-9", model "gpt-x", content "calling", two tool calls (valid and "garbage" arguments), finish `tool_calls`, usage 11 and 4 | id "msg_chatcmpl-9"; text block, tool_use c1 with input k=v, tool_use c2 with empty input; stop reason `tool_use`; usage input 11, output 4 |
| anthropic-chat-translation-024 | reply-model, reply-malformed (`testNonStreamedFallbackModelAndMalformed`) | A reply with no model and finish `length`; then `{}` | model "fb" and stop reason `max_tokens`; then `malformedReply` |
| anthropic-chat-translation-025 | error-message-source, error-type-map (`testErrorMapping`) | Status 429 with an OpenAI-style error object "slow down"; status 500 with plain text; status 502 with 900 characters; statuses 400, 401, 403, 404, 413, 529 with empty bodies | `rate_limit_error` "slow down"; `api_error` with the text; message of 500 characters; the mapped type for each status |
| anthropic-chat-translation-026 | request-no-messages | `{"messages":[{"role":"user","content":"hi"},"oops"]}` | `noMessages` thrown, because the array is not all objects |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` (request) | text | none (required) | Provider model name placed in the Chat Completions request. |
| `maxTokensKey` | text | `max_tokens` | Name under which the request's `max_tokens` is written; a provider using `max_completion_tokens` passes that name. |
| `fallbackModel` | text | none (required) | Model reported when the reply names none. |
| `status`, `body` | integer, bytes | none (required) | Provider HTTP status and body for `anthropicError`. |
| stream `model` | text | none (required) | Model named in `message_start`. |
| stream `messageID` | text | `msg_` plus a hyphenless UUID | Message id in `message_start`. |

## Deep Linking

Not applicable: the source defines no URL, route or navigable destination.

## Localization

The source contains three hardcoded English strings: the `[image omitted]` placeholder, the `Error: ` prefix on failed tool results, and the fallback stream error text `provider stream error`. They are not localized and not externalized; they are part of the wire text sent to a model or client, not interface text for people. Provider error messages pass through as the provider wrote them.

## Accessibility Options

Not applicable: the component renders nothing and reads no accessibility display setting.

## Feature Flags

Not applicable: the source declares no feature-flag key and contains no conditional gating beyond the caller's `maxTokensKey` argument.

## Analytics

Not applicable: the source contains no analytics or event-emission call.

## Privacy

- **Data collected**: The component sees prompts, system text, tool arguments and results, image data (including base64 images, copied into `data:` URLs) and reply text. It records none of it.
- **Storage**: None; in memory for one call, or for one response in the stream translator's buffer.
- **Transmission**: The component sends nothing; the caller sends the translated body to the provider, so everything translated reaches the provider the caller chooses. No credential is read or written.
- **Retention**: None beyond the instance's life. Provider error bodies can carry text the provider chose to include and are passed on, truncated to 500 characters when they have no message field.

## Logging

Not applicable: the component contains no logging call; failures are returned or thrown, not logged.

## Platform Notes

- **SwiftUI**: not applicable to this file; it imports only `Foundation`. A SwiftUI chat screen would not call it; it sits in the daemon or proxy path between an Anthropic-speaking client and an OpenAI-compatible provider.
- **Compose**: use `kotlinx.serialization.json` `JsonObject` trees or Moshi `Map<String, Any?>` for pass-through, a `sealed` error class or exception for `TranslationError`, and a `Flow<ByteArray>` transform (or an OkHttp interceptor with `BufferedSource`) for the streaming class; keep the stream translator single-owner per call.
- **React/Web**: use plain objects with `JSON.parse` and `JSON.stringify`; model the stream as a `TransformStream` or an async generator that holds a text buffer, with a `TextDecoder` in streaming mode so multi-byte characters survive byte splits. Single-threaded JavaScript removes the interleaving question, but one transform per response is still required. Event key order from `JSON.stringify` differs from Foundation's, so compare parsed events in tests.
- **AppKit / UIKit**: this is the source. The file is `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AnthropicChatTranslation.swift` in the `AIPluginKit` framework: a `public enum AnthropicChatTranslation` (nested `TranslationError`) and a `public final class ChatCompletionsStreamTranslator`. It uses `JSONSerialization` on `[String: Any]`, `NSNull` for JSON null, and `UUID().uuidString` for generated ids. `stopReason(forFinish:)` is internal and shared by both parts. Nothing outside tests calls it in the repository today.
- **WinUI 3**: use `System.Text.Json.Nodes` (`JsonNode`, `JsonObject`, `JsonArray`) for pass-through, since `JsonSerializer` into fixed records would lose unknown fields; model `TranslationError` as an exception class with an enum code, or a result type. Build the streaming part as a class with a `StringBuilder` or `Utf8` buffer reading from `HttpResponseMessage.Content.ReadAsStreamAsync()` (with `HttpCompletionOption.ResponseHeadersRead`), splitting on `\n`, and writing events to the response through `IAsyncEnumerable<byte[]>`. In ASP.NET Core, expose it as a minimal API route returning `Results.Stream` with content type `text/event-stream`. Use `Guid.NewGuid().ToString("N")` for hyphenless ids, `JsonValueKind.Null` / `null` JsonNode for `NSNull`, and `Dictionary<int, ToolCall>` for call state. Do not share one translator across requests, and keep tool-call bookkeeping on one `Task`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AnthropicChatTranslation.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Translation operates on untyped JSON dictionaries and copies only known fields; unknown content blocks and Anthropic-only fields are dropped.
**Rationale**: The doc comment says "only structural failure throws, unknown content blocks are dropped". Providers differ in what they accept, so dropping unknown input (thinking, cache control, metadata) keeps requests valid, at the cost of silently losing that data.
**Approved**: pending

**Decision**: The stream translator keeps at most one content block open and drops a late fragment for a tool call whose block has closed.
**Rationale**: The source comment states Anthropic's streaming format requires one open block at a time and "Anthropic cannot reopen" a closed block. Providers that interleave parallel tool-call fragments therefore lose the later fragments of an earlier call.
**Approved**: pending

**Decision**: A tool block starts only when the call has a name, buffering arguments until then; at the end, named pending calls start in descending key order and unnamed ones are dropped.
**Rationale**: An Anthropic `tool_use` start needs a name. The descending order is what the code does; the source gives no reason, and for keyless calls (negative keys counting down) it means arrival order, while for indexed calls it means highest index first.
**Approved**: pending

**Decision**: `maxTokensKey` is an argument and `max_tokens` is never defaulted.
**Rationale**: Some OpenAI-compatible providers want `max_completion_tokens`; the caller picks the name. Anthropic requires `max_tokens`, but this translator forwards the request's value only when present and leaves enforcement to the provider.
**Approved**: pending

**Decision**: Reply tool arguments that fail to parse as an object become an empty input object, and stream arguments are forwarded unvalidated.
**Rationale**: A whole reply must return a valid Anthropic message, so bad arguments are replaced; a stream cannot know completeness mid-flight, so it forwards fragments. The two paths therefore differ for invalid arguments.
**Approved**: pending

**Decision**: The stream's closing `message_delta` includes `input_tokens` as well as `output_tokens`, and `message_start` reports zero usage.
**Rationale**: Chat Completions reports usage once, late; the translator holds it for the closing event. This differs from Anthropic's own stream, where input usage arrives at the start. A reader such as the Anthropic response reader picks both up, because it applies usage from either event.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |

`separation-of-concerns` passes because the component only transforms bytes: it opens no connection, reads no setting and holds no credential, leaving transport, retry and timeout to the caller. `unit-test-coverage` passes because `AnthropicChatTranslationTests` covers request translation for system, user, assistant, tool, image and option paths, the non-streamed reply, error mapping, and streaming behavior including byte-wise feeding, CRLF, interleaving, `[DONE]`, mid-stream errors and double finish. `explicit-error-handling` is partial because structural failure throws a typed error, while lossy cases (dropped blocks, replaced bad tool arguments, dropped late fragments) give the caller no signal; these are deliberate, per the source's own comment. `error-response-handling` passes because every HTTP status maps to an Anthropic error type with a message, with an explicit fallback. `input-sanitization` is partial because the component checks structure, not content: tool arguments in a stream are forwarded unvalidated, and provider messages pass through as written. `no-hardcoded-strings` is partial because three English strings are written into the output (see Localization), though none is interface text.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
