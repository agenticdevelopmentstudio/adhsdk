---
id: f333f036-2c23-4a87-8496-bd3616b44786
title: "Claude Stream JSON"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Decodes one line of claude -p --output-format stream-json into a typed message, detects a lost --resume session, and builds the user-message line written to stdin."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - claude
  - json
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Claude Stream JSON

## Overview

The wire adapter between the app and the `claude` command-line process run with `claude -p --output-format stream-json`. `ClaudeStreamMessage.decode(_:)` turns one output line into a `ClaudeStreamMessage` (a kind, a subtype, a session id, content blocks, an error flag, a result text, a turn count and a list of error strings). `reportsLostSession` recognises the error result claude emits when `--resume` names a session it does not have. `ClaudeStreamInput.userMessage(_:)` builds the single newline-terminated JSON line the app writes to claude's stdin. Decoding is deliberately lenient: it reads the fields it knows and ignores the rest, and only a line that is not a JSON object is an error.

## Behavioral Requirements

**Message shape**

- **message-fields**: `ClaudeStreamMessage` MUST carry `kind`, `subtype` (optional String), `sessionID` (optional String), `blocks` (an array of `Block`), `isError` (Bool), `resultText` (optional String), `numTurns` (optional Int) and `errors` (an array of String), and MUST be `Sendable` and `Equatable`.
- **message-init-defaults**: The `ClaudeStreamMessage` initializer MUST require `kind` and MUST default `subtype`, `sessionID`, `resultText` and `numTurns` to `nil`, `blocks` and `errors` to empty arrays and `isError` to `false`.
- **message-kinds**: `ClaudeStreamMessage.Kind` MUST have the cases `systemInit`, `assistant`, `user` and `result`, plus `other` carrying the original type string.
- **block-fields**: `ClaudeStreamMessage.Block` MUST carry `kind`, `text`, `name`, `id` and `toolUseID`, where all but `kind` are optional Strings, and its initializer MUST default each optional field to `nil`.
- **block-kinds**: `Block.Kind` MUST have the cases `text`, `toolUse`, `toolResult`, `thinking` and `other`.

**Decoding a line**

- **decode-not-json-throws**: `decode(_:)` MUST throw `DecodingError.dataCorrupted` with the debug description "not JSON" when the line is not parseable JSON, including an empty line, and MUST carry the parser error as the underlying error.
- **decode-not-object-throws**: `decode(_:)` MUST throw `DecodingError.dataCorrupted` with the debug description "not a JSON object" when the line parses but its top level is not an object.
- **decode-kind-mapping**: `decode(_:)` MUST map `type` `"assistant"` to `.assistant`, `"user"` to `.user`, `"result"` to `.result`, and `"system"` with `subtype` `"init"` to `.systemInit`.
- **decode-kind-other**: `decode(_:)` MUST map any other `type` to `.other(type)` with the type string unchanged, including a `"system"` message whose subtype is not `"init"`.
- **decode-missing-type**: `decode(_:)` MUST map an object with no string `type` to `.other("")`.
- **decode-subtype**: `decode(_:)` MUST copy a string `subtype` into `subtype` and leave it `nil` otherwise.
- **decode-session-id**: `decode(_:)` MUST read `sessionID` from the key `session_id` when it is a string.
- **decode-is-error**: `decode(_:)` MUST read `isError` from the key `is_error` when it is a Bool and MUST default it to `false` otherwise.
- **decode-result-text**: `decode(_:)` MUST read `resultText` from the key `result` when it is a string.
- **decode-num-turns**: `decode(_:)` MUST read `numTurns` from the key `num_turns` when it is an integer.
- **decode-errors**: `decode(_:)` MUST read `errors` from the key `errors` when it is an array, keeping only the string elements in order and dropping the others; it MUST yield an empty array when the key is missing or not an array.
- **decode-ignores-unknown**: `decode(_:)` MUST ignore keys it does not read; they cause no error.

**Content blocks**

- **blocks-from-array**: When `message.content` is an array of objects, `decode(_:)` MUST produce one `Block` per element, in order.
- **blocks-from-string**: When `message.content` is a string, `decode(_:)` MUST produce exactly one `.text` block carrying that string.
- **blocks-otherwise-empty**: `decode(_:)` MUST produce an empty `blocks` array when `message` is missing or not an object, or when its `content` is neither a string nor an array of objects.
- **block-text**: A content element with `type` `"text"` MUST become a `.text` block whose `text` is the element's `text` string.
- **block-thinking**: A content element with `type` `"thinking"` MUST become a `.thinking` block whose `text` is the element's `thinking` string.
- **block-tool-use**: A content element with `type` `"tool_use"` MUST become a `.toolUse` block carrying the element's `name` and `id`, and no text; the tool input is not carried.
- **block-tool-result-string**: A `"tool_result"` element whose `content` is a string MUST become a `.toolResult` block whose `text` is that string and whose `toolUseID` is the element's `tool_use_id`.
- **block-tool-result-parts**: A `"tool_result"` element whose `content` is an array of objects MUST become a `.toolResult` block whose `text` is the `text` strings of the parts that have one, joined with a newline.
- **block-tool-result-no-content**: A `"tool_result"` element whose `content` is neither a string nor an array of objects MUST become a `.toolResult` block with `text` of `nil`.
- **block-other**: A content element with any other `type`, or none, MUST become a `.other` block with every field `nil`.

**Lost session**

- **lost-session-text**: `ClaudeStreamMessage.lostSessionText` MUST equal `"No conversation found"`, which is what claude says on stdout and stderr alike when `--resume` names a session it does not have.
- **reports-lost-session**: `reportsLostSession` MUST be true only when `kind` is `.result`, `isError` is true and at least one entry of `errors` contains `lostSessionText` as a substring.
- **lost-session-not-other-errors**: `reportsLostSession` MUST be false for an error result whose `errors` do not contain `lostSessionText`, such as an authentication or quota failure before any turn ran.

**Input line**

- **user-message-shape**: `ClaudeStreamInput.userMessage(_:)` MUST return UTF-8 JSON for an object with `type` `"user"` and `message` an object with `role` `"user"` and `content` an array of one element `{"type":"text","text":<the text>}`.
- **user-message-newline**: `userMessage(_:)` MUST end its output with a single line feed byte (`0x0A`).
- **user-message-slashes**: `userMessage(_:)` MUST NOT escape forward slashes in the text.
- **user-message-key-order**: `userMessage(_:)` MUST NOT promise a key order; the source requests none.
- **user-message-cannot-fail**: `userMessage(_:)` MUST NOT return a failure for any Swift string; a serialisation failure is a programmer error that stops the process with a precondition failure, because a user message is plain strings and always serializes.

## Appearance

Not applicable — this is a protocol decoder and encoder, not a visual component.

## States

Not applicable — this is a protocol decoder and encoder, not a visual component. The types are stateless values and functions.

## Accessibility

Not applicable — this is a protocol decoder and encoder, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-stream-json-001 | decode-kind-mapping, blocks-from-array, block-text, block-tool-use | Test `decodesAssistantTextAndToolUse`: `{"type":"assistant","session_id":"s","message":{"role":"assistant","content":[{"type":"text","text":"hi"},{"type":"tool_use","id":"t1","name":"mcp__adkitchen__partner_notify","input":{}}]}}` | `kind == .assistant`, two blocks, and `blocks[1].name == "mcp__adkitchen__partner_notify"` |
| claude-stream-json-002 | decode-kind-mapping, decode-is-error, decode-subtype | Test `decodesResultError`: `{"type":"result","subtype":"error_max_turns","is_error":true,"result":"x","session_id":"s"}` | `kind == .result`, `isError == true`, `subtype == "error_max_turns"` |
| claude-stream-json-003 | decode-num-turns, decode-errors, reports-lost-session | Test `decodesClaudesUnknownSessionResult`: an error result with subtype `error_during_execution`, `num_turns` 0 and `errors` `["No conversation found with session ID: 11111111-2222-3333-4444-555555555555"]` | `numTurns == 0`, `errors` equals that one string, `reportsLostSession` is true |
| claude-stream-json-004 | lost-session-not-other-errors | Test `anOrdinaryResultDoesNotReportALostSession`: a `success` result (`is_error` false, `num_turns` 1) and an `error_max_turns` result (`is_error` true, `num_turns` 3) | `reportsLostSession` is false for both, and the success result's `errors` is empty |
| claude-stream-json-005 | lost-session-not-other-errors | Test `anErrorBeforeAnyTurnIsNotALostSessionUnlessItSaysSo`: an error result with `num_turns` 0 and `errors` `["Invalid API key"]` | `reportsLostSession` is false |
| claude-stream-json-006 | decode-kind-other | Test `unknownTypeIsOther`: `{"type":"stream_event","event":{}}` | `kind == .other("stream_event")` |
| claude-stream-json-007 | decode-not-json-throws | Test `nonJSONThrows`: the bytes `nope` | `decode` throws `DecodingError` |
| claude-stream-json-008 | decode-kind-mapping, decode-session-id | Test `systemInitDecodes`: `{"type":"system","subtype":"init","session_id":"s"}` | `kind == .systemInit` and `sessionID == "s"` |
| claude-stream-json-009 | user-message-shape, user-message-newline | Test `userMessageLineShape`: `userMessage("hello")` | Parsed JSON has `type` `"user"`, `message.role` `"user"` and `message.content[0].text` `"hello"`; `userMessage("x")` ends in byte `0x0A` |
| claude-stream-json-010 | decode-kind-other | `{"type":"system","subtype":"api_retry"}` | `kind == .other("system")` and `subtype == "api_retry"` |
| claude-stream-json-011 | decode-missing-type | `{}` | `kind == .other("")`, `blocks` empty, `isError == false`, `errors` empty |
| claude-stream-json-012 | decode-not-object-throws | `[1,2]` | Throws `DecodingError.dataCorrupted` described as "not a JSON object" |
| claude-stream-json-013 | decode-not-json-throws | An empty `Data` | Throws `DecodingError.dataCorrupted` described as "not JSON" |
| claude-stream-json-014 | blocks-from-string | `{"type":"user","message":{"role":"user","content":"plain"}}` | One `.text` block with `text == "plain"` |
| claude-stream-json-015 | block-thinking | Content element `{"type":"thinking","thinking":"hmm"}` | A `.thinking` block with `text == "hmm"` |
| claude-stream-json-016 | block-tool-result-string | Content element `{"type":"tool_result","tool_use_id":"t1","content":"ok"}` | A `.toolResult` block with `text == "ok"` and `toolUseID == "t1"` |
| claude-stream-json-017 | block-tool-result-parts | Content element `{"type":"tool_result","tool_use_id":"t1","content":[{"type":"text","text":"a"},{"type":"image"},{"type":"text","text":"b"}]}` | `text == "a\nb"` |
| claude-stream-json-018 | block-tool-result-no-content | Content element `{"type":"tool_result","tool_use_id":"t1"}` | A `.toolResult` block with `text == nil` |
| claude-stream-json-019 | block-other | Content element `{"type":"image"}` | A `.other` block with all fields `nil` |
| claude-stream-json-020 | decode-errors | `{"type":"result","errors":["a",1,"b"]}` | `errors == ["a", "b"]` |
| claude-stream-json-021 | user-message-slashes | `userMessage("a/b")` | The bytes contain `a/b` and not `a\/b` |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ClaudeStreamMessage.lostSessionText` | String | `"No conversation found"` | The phrase claude emits when `--resume` names a missing session. |
| `userMessage` text | String | none (required) | The prompt text to send. |
| JSON writing options | fixed | `withoutEscapingSlashes` | The options used to write the input line; not configurable. |

## Deep Linking

Not applicable: The file decodes and encodes protocol lines and registers no URL scheme, route or link handler.

## Localization

Not applicable: The file has no user-facing strings of its own. `lostSessionText` is claude's English phrase matched as a protocol token, and `resultText` and `errors` are passed through as claude wrote them.

## Accessibility Options

Not applicable: The file has no visual surface, so no Reduce Motion, Increase Contrast or Differentiate Without Color behavior exists.

## Feature Flags

Not applicable: The source reads no flag.

## Analytics

Not applicable: The source emits no analytics events.

## Privacy

- **Data collected**: None by this code. It carries the conversation: the owner's prompt text (`userMessage`), assistant text, thinking text, tool names and tool results, which may contain project content.
- **Storage**: None; the file persists nothing.
- **Transmission**: None directly; the lines it builds are written by the caller to a local claude process's stdin, and claude then talks to its own service.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: The source calls no logging API; a bad line is reported to the caller as a thrown `DecodingError`.

## Platform Notes

- **SwiftUI**: The source is `Core/Partner/ClaudeStreamJSON.swift` and imports only `Foundation`, so a SwiftUI host uses it unchanged. It uses `JSONSerialization` with `[String: Any]` casting rather than `Codable`, which is what makes it tolerant of unknown keys and shapes. `ClaudeStreamInput` is a caseless `enum`.
- **Compose**: Parse each line with `kotlinx.serialization.json.Json.parseToJsonElement` and read fields through `JsonObject` with `jsonPrimitive.contentOrNull`, so a wrong type reads as null rather than throwing; throw `SerializationException` for a non-object. Spawn claude with `ProcessBuilder` and write the input line with a trailing `\n` to its `outputStream`.
- **React/Web**: Use `JSON.parse` in a `try`/`catch`, check `typeof` and `Array.isArray` for each field, and return the same discriminated union (`kind`, optional strings). A browser cannot spawn claude; this applies to a Node or Electron host using `child_process.spawn`. `JSON.stringify` does not escape slashes, which matches `withoutEscapingSlashes`; append `"\n"`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the types carry no UI. A macOS app reads claude's stdout through `Pipe` and `FileHandle` and decodes per line.
- **WinUI 3**: Use `System.Text.Json.JsonDocument.Parse` (catch `JsonException` and rethrow as an `InvalidDataException` with the same two messages) and `TryGetProperty` with `ValueKind` checks so wrong types read as absent; model the kind as a discriminated record or an enum plus an `OtherType` string. Read the process with `System.Diagnostics.Process` and `StandardOutput.ReadLineAsync`, and write the input with `Utf8JsonWriter` using `JavaScriptEncoder.UnsafeRelaxedJsonEscaping` (so slashes stay unescaped) followed by `\n` to `StandardInput`. `List<string>` for `errors`, with `Errors.Any(e => e.Contains("No conversation found"))` for the lost-session check.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/ClaudeStreamJSON.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Decoding uses `JSONSerialization` and manual casts rather than `Codable`.
**Rationale**: Claude's stream has many message and block types and the app reads a few fields from each; manual casts let every unknown shape degrade to `.other` or `nil` instead of failing the line. Only a line that is not a JSON object throws.
**Approved**: pending

**Decision**: `reportsLostSession` requires an error `result` whose `errors` contain the phrase, not just the phrase anywhere.
**Rationale**: The source comment says claude emits an error `result` and then exits for a `--resume` id it does not have, and that other errors before any turn ran (authentication, quota) are not a lost session; matching the structured field keeps those from being treated as a lost session.
**Approved**: pending

**Decision**: A `tool_use` block carries its name and id but not its input.
**Rationale**: The source reads only `name` and `id` for it; consumers identify which tool ran (for example an MCP notify tool) without the arguments, which are not retained in the decoded message.
**Approved**: pending

**Decision**: A `tool_result` with array content joins the parts' text with a newline, and parts without text contribute nothing.
**Rationale**: The source flattens the parts to one string for display; non-text parts are dropped, so a result made only of non-text parts yields an empty string rather than `nil`.
**Approved**: pending

**Decision**: `userMessage` stops the process with a precondition failure if serialisation fails, instead of throwing.
**Rationale**: The source message states a user message is plain strings and always serializes; a failure would be a programmer error, and a non-throwing signature keeps every caller simple.
**Approved**: pending

**Decision**: The input line is terminated with a line feed and escapes no slashes.
**Rationale**: Claude reads stream-json input one line per message, so the newline is the message delimiter; unescaped slashes keep paths and URLs in prompts readable.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes because the file only decodes lines and encodes the input line; spawning claude, reading its pipes and acting on messages belong to the process and session types. `unit-test-coverage` passes: every vector, 001 to 021, has a test in `AgenticDeveloperHubSDKCoreTests/Partner/ClaudeStreamJSONTests.swift`, covering assistant text and tool use, error results, the lost-session cases, unknown types, non-JSON input, system init, the input line shape, thinking blocks, `tool_result` content, string message content, the top-level-array error, the dropped non-string errors and unescaped slashes. `explicit-error-handling` passes because a bad line raises a typed `DecodingError` with a stated reason. `graceful-degradation` passes because unknown message types, block types and field shapes decode to `.other` or absent values rather than failing.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ClaudeStreamJSONTests.swift, 21 of 21 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Narrowed the wrong-type edge case to the NSNumber bridging, fixed the not-object requirement, added a mixed-content decision, a non-text tool_result requirement, links, new tags and vectors 022-027. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
