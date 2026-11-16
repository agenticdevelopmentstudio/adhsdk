---
id: 5f18890e-5473-4315-9e69-dde7c64778bc
title: "Prompted Tool Calling Plugin"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wraps an AI plugin to give tools to a provider without native tool calling, by describing tools in the prompt and lifting tool_call blocks from the reply."
platforms:
  - swift
  - macos
tags:
  - ai
  - plugin
  - tool-calling
  - decoder
depends-on:
  - 47eb19ef-2c42-4a52-a60b-54b6f01c8791
  - 2067e249-4f97-4575-b8ed-8f55f6dc96df
  - 72829b3b-ce4a-4730-877f-da7b48e7b3dd
  - 613d7a36-d0cd-4415-97be-d983b3d6c644
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# Prompted Tool Calling Plugin

## Overview

The Prompted Tool Calling Plugin gives tools to a plugin whose provider has no tool calling of its own, or whose plugin does not send the context's tools to the provider. It is a decorator over another plugin. It describes the tools in the system prompt and asks the model to request each call as a `<tool_call>` block of JSON in its reply text. A decoder holds the reply back until it ends, lifts those blocks out as tool-use events, and passes the rest on as text. Earlier calls and their results are written back into the conversation as text in the same format, so the history reads as one protocol.

Holding the reply back costs streaming, which is why this is opt-in for a caller that needs tools rather than applied to every plugin. It conforms to the AI plugin contract ([adhsdk.ingredient.ai.ai-plugin](cookbook:47eb19ef-2c42-4a52-a60b-54b6f01c8791)), reads and writes the chat context ([adhsdk.ingredient.ai.chat-context](cookbook:613d7a36-d0cd-4415-97be-d983b3d6c644)), returns request descriptions ([adhsdk.ingredient.ai.request-spec](cookbook:72829b3b-ce4a-4730-877f-da7b48e7b3dd)) and emits stream events ([adhsdk.ingredient.ai.stream-event](cookbook:2067e249-4f97-4575-b8ed-8f55f6dc96df)). Where tools are served over MCP, see [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56).

The source is `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/PromptedToolCallingPlugin.swift`. It holds a public final class, `PromptedToolCallingPlugin`, and an internal `PromptedToolCallDecoder`.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a plugin decorator and a stream decoder, not a visual component.

## States

The decoder has two states, accumulating and flushed; the plugin itself is stateless.

| State | Entered when | Behavior |
|-------|-------------|----------|
| accumulating | The decoder is created | Text deltas from the wrapped decoder are appended to the reply and nothing is emitted; native tool-use events pass through. |
| flushed | The wrapped decoder reports the end, or `finish()` runs without one | The prose, calls and end event have been emitted once; later ends are dropped. |

## Accessibility

Not applicable — this is a plugin decorator and a stream decoder with no user interface.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| prompted-tool-calling-plugin-001 | build-no-tools-passthrough | A context with system prompt `be kind`, no tools, empty config | The wrapped plugin sees system prompt `be kind` and no built-in-tools setting (`PromptedToolCallingPluginTests.passesThrough`) |
| prompted-tool-calling-plugin-002 | build-tools-into-prompt, build-tools-emptied, build-builtins-off, instructions-catalog | A context with system prompt `be kind` and a tool `run` described `Run a command.` | The wrapped plugin sees a prompt starting `be kind` and containing `- run: Run a command.`, an empty tools list, and built-in tools `none` (`describesTools`) |
| prompted-tool-calling-plugin-003 | history-call-block, history-call-joins-assistant, history-result-label, history-result-joins-user | History: user `where am I?`, assistant `Checking.`, tool use `run` with `{"command":"pwd"}`, tool result `/Users/bobby` | Roles become user, assistant, user; the assistant message contains `<tool_call>{"name": "run", "arguments": {"command":"pwd"}}</tool_call>`; the last message is `[Tool result]` newline `/Users/bobby` (`textualHistory`) |
| prompted-tool-calling-plugin-004 | decode-hold-text, decode-flush-at-end, decode-call-ids, decode-stop-reason, parse-lift-blocks | Decode chunk `Let me look.` newline `<tool_call>{"name": "run", ` (no events yet), then `"arguments": {"command": "pwd"}}</tool_call>`, then `finish()` | Exactly three events: text `Let me look.`, a tool use named `run` with arguments `{"command":"pwd"}`, and an end with reason `tool_use` (`decodesCalls`) |
| prompted-tool-calling-plugin-005 | parse-malformed-kept | Parse `oops <tool_call>not json</tool_call> done` | No calls and the text is unchanged (`keepsMalformedBlocks`) |
| prompted-tool-calling-plugin-006 | parse-unclosed-kept | Parse `a <tool_call>{"name":"run"} b` | No calls and the text is `a <tool_call>{"name":"run"} b` (derived from `parse`; no test) |
| prompted-tool-calling-plugin-007 | decode-stop-reason | A wrapped decoder yielding text `hello` then end `end_turn` | Events are text `hello`, then end `end_turn` (derived from `flush`; no test) |
| prompted-tool-calling-plugin-008 | decode-call-ids, parse-order | A reply with two valid blocks | Two tool-use events with ids `prompted-1` and `prompted-2` in reply order (derived from `flush`; no test) |
| prompted-tool-calling-plugin-009 | decode-native-tool-use-passes | A wrapped decoder yielding a native tool use | The tool use is emitted at once, before any flush (derived from `absorb`; no test) |
| prompted-tool-calling-plugin-010 | decode-finish-flushes, decode-flush-once | A wrapped decoder that yields text but never an end; then `finish()` | Text and an end with no stop reason are emitted once; a second `finish()` emits nothing more from the reply (derived from `finish`; no test) |
| prompted-tool-calling-plugin-011 | wrap-nothing-fails | `PromptedToolCallingPlugin()` then `buildRequest` | Throws an error described as "PromptedToolCallingPlugin was created without a plugin to wrap." (derived from `NothingWrapped`; no test) |
| prompted-tool-calling-plugin-012 | build-empty-prompt-omitted | A context with tools and a nil system prompt | The wrapped plugin's prompt is exactly the instructions, with no leading blank lines (derived from the `compactMap` and `filter`; no test) |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plugin` (parameter of `init(wrapping:)`) | `any AIPlugin` | none — required | The plugin whose request building, decoder, validation and error description are wrapped. |
| `AIPluginConfig.builtInToolsKey` | config key, value `builtInTools` | set to `none` when tools are described | Switches the wrapped plugin's own built-in tools off for the turn. |
| `openTag`, `closeTag` | `String` constants | `<tool_call>` and `</tool_call>` | The delimiters of a call block. |
| Call id prefix | constant inside the source | `prompted-` plus a counter from 1 | The ids given to lifted calls. |

## Deep Linking

Not applicable: it is a request decorator and stream decoder and defines no app deep link or navigation destination.

## Localization

Not applicable for user-facing text: the tool instructions are a prompt to a language model, written in English; whether to localize them is not addressed by the source. The only other string is the developer-facing failure message for a plugin made without one to wrap.

## Accessibility Options

Not applicable: the component renders no UI, so it observes no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: it reads no flag. It is opt-in by being applied: a caller wraps a plugin in it only when it needs tools.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: The conversation, the tool descriptions, the tool arguments and the tool results all pass through it; arguments and results are written into the prompt text sent to the provider.
- **Storage**: It stores nothing durable. A decoder holds the reply text in memory until it ends.
- **Transmission**: It transmits nothing itself; the wrapped plugin's request carries the rewritten messages and prompt to the provider, so tool results leave the app as prompt text exactly as ordinary messages would.
- **Retention**: A decoder's reply is discarded with the decoder.
- **Tool results as text**: Because results become user-message text, whatever a tool returns is visible to the provider, as with any message.

## Logging

Not applicable: the source makes no logging call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/PromptedToolCallingPlugin.swift`, in the AIPluginKit framework, which also imports `AgenticDeveloperHubSDKCore`. The macOS chat surface (`PersonaTerminalChatViewController`) wraps the plugin it loads before use, and the chat then sees tool-use events instead of streamed text on tool turns; it should show a busy state while the reply is held back, since no text arrives until the end.
- **Compose**: Port as a class implementing the app's plugin interface by delegation, with the decoder as a stateful class per reply. Parse with `indexOf` on the two tags and `org.json.JSONObject` or `kotlinx.serialization.json`; the held-back reply means the UI must show progress without text.
- **React/Web**: Port as a function that wraps a provider adapter: `buildRequest` rewrites messages and system prompt, and a stream decoder accumulates text and emits events at the end. Use `JSON.parse` in a `try` for block bodies and a loop over `indexOf` for the tags. The held-back reply means a streaming UI shows a spinner until the end event.
- **AppKit / UIKit**: Identical to the SwiftUI note; the type is UI-free, and the AppKit or UIKit chat surface only needs a pending indicator while the decoder holds the reply.
- **WinUI 3**: Implement as a class decorating the plugin interface, with a per-reply decoder class. Use `string.IndexOf` with ordinal comparison for tags and `System.Text.Json.JsonDocument.Parse` in a `try` for block bodies, falling back to prose on `JsonException`. Bind a progress ring to the pending state until the end event arrives.

## Design Decisions

**Decision**: Tools are described in the system prompt and requested as `<tool_call>` JSON blocks in the reply text.
**Rationale**: The doc comment says it serves a provider that has no tool calling of its own, or whose plugin does not send the context's tools, so text is the only channel every provider has.
**Approved**: pending

**Decision**: The decoder holds the whole reply back until it ends.
**Rationale**: A block can be split across any chunk boundary, so the decoder cannot know whether a fragment is prose or a call until the reply ends; the comment names the cost, streaming, and the opt-in nature that follows from it.
**Approved**: pending

**Decision**: Earlier calls and results are written back into the history as text in the same block format.
**Rationale**: The comment says this makes the history read as one protocol, since the provider has no other way to see them.
**Approved**: pending

**Decision**: A malformed block stays in the prose.
**Rationale**: The comment says the user should see what the model wrote rather than lose it.
**Approved**: pending

**Decision**: Built-in tools are switched off for a turn that describes tools.
**Rationale**: The source comment says the described tools are the only ones the turn may use.
**Approved**: pending

**Decision**: A provider's native tool-use events pass through the decoder immediately.
**Rationale**: The comment says a provider that does call tools natively still gets through.
**Approved**: pending

**Decision**: A parameterless initializer wraps a plugin that fails every request with a clear message.
**Rationale**: The plugin contract requires it for loading a principal class from a bundle, which a wrapper never is, so a misuse fails loudly instead of silently producing nothing.
**Approved**: pending

**Decision**: The type is a wrapper that others opt into, not a base class or a change to every plugin.
**Rationale**: Wrapping keeps the buffering cost, which the comment names, with only the caller that needs tools.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.performance.progress-indication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6ba6685b-9d35-5eb2-96e7-afbccd1e5848) | partial | Performance |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the plugin only translates between the tool protocol and plain text, leaving transport, provider and tool execution to others. `unit-test-coverage` is partial: the suite covers pass-through, prompt building, history, a split block and a malformed block, but no test drives an unclosed tag, several calls, a native tool use, a decoder with no end, or the wrap-nothing failure. `explicit-error-handling` passes: a plugin built with nothing wrapped fails every request with a described error, and a bad block is kept visible rather than dropped. `progress-indication` is partial because the decoder emits nothing until the reply ends, leaving the caller to show a busy state. `input-sanitization` is partial: model output is parsed as JSON in a `try` and falls back to prose, but call names are not checked against the tools that were offered, so that check belongs to whatever executes the calls.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Platforms name macOS, the source platform |
