---
id: d3c2efb6-5ba6-4301-81d7-a25248b0992a
title: "Anthropic Response Reader"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A passive, never-throwing reader that extracts model, token usage and stop reason from an Anthropic response, streamed or whole, for the record."
platforms:
  - swift
  - macos
tags:
  - ai-plugin
  - anthropic
  - response-parsing
  - streaming
depends-on: []
related:
  - 4d7ed9a3-c6d8-491b-911a-cf257fde1c38
references: []
approved-by: ""
approved-date: ""
---

# Anthropic Response Reader

## Overview

`AnthropicResponseReader` is a class that watches the bytes of one Anthropic Messages response and records six facts about it: `model`, `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheCreationTokens` and `stopReason`. Its doc comment states the contract: "Passive reader of an Anthropic response (SSE or JSON) for the record. Never alters bytes, never throws, tolerates arbitrary chunking. Not thread-safe; one per response." A caller creates one reader per response, feeds it each chunk with `consume`, calls `finish` once the body ends, and reads the six properties. A streaming reader parses server-sent events line by line; a non-streaming reader buffers a JSON body and parses it at the end. A field the response never supplies, or that the reader could not read, stays nil. The reader makes no network call and writes no file.

## Behavioral Requirements

- **init-mode**: The reader MUST be created with `init(streaming:)`, and that flag MUST fix its mode for its lifetime: `true` for a server-sent-event body, `false` for a single JSON body.
- **output-fields**: The reader MUST expose six read-only optional properties: `model` and `stopReason` (text) and `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheCreationTokens` (integers). Each MUST be nil until a value is read.
- **never-throws**: No operation MAY throw; malformed, truncated or non-UTF-8 input MUST leave the fields untouched rather than raise an error.
- **passive**: The reader MUST NOT alter or return the bytes it is given; `consume` and `finish` return nothing.
- **chunking-independence**: Splitting the same body at any byte boundary MUST yield the same field values as feeding it whole, provided no single line reaches the 4 MiB cap (a longer line is parsed when fed whole in one chunk, but discarded when the cap trips between chunks).
- **sse-line-framing**: In streaming mode the reader MUST accumulate chunks and process each complete line ending in a line feed (byte 0x0A), removing a single trailing carriage return (0x0D) before processing, so both LF and CRLF framing work.
- **sse-data-lines-only**: In streaming mode a line MUST be processed only if it decodes as UTF-8 and starts with `data:`; every other line (`event:` lines, comments, blank lines, invalid bytes) MUST be ignored.
- **sse-data-prefix**: The reader MUST strip the `data:` prefix and one optional single leading space before parsing the remainder as JSON.
- **sse-payload-object**: A `data:` payload MUST be used only if it parses as a JSON object; any other payload (broken JSON, an array, a scalar) MUST be ignored.
- **sse-message-start**: For an event whose `type` is `message_start` the reader MUST set `model` from `message.model` when it is text, and apply `message.usage`.
- **sse-message-delta**: For an event whose `type` is `message_delta` the reader MUST set `stopReason` from `delta.stop_reason` when it is text, and apply the event's top-level `usage`.
- **sse-other-events-ignored**: Events of any other `type`, or with no `type`, MUST NOT change any field.
- **usage-keys**: Applying a usage object MUST set `inputTokens` from `input_tokens`, `outputTokens` from `output_tokens`, `cacheReadTokens` from `cache_read_input_tokens` and `cacheCreationTokens` from `cache_creation_input_tokens`, each only when that key holds an integer.
- **usage-last-write-wins**: A later usage value MUST overwrite an earlier one for the same key, and a usage object that omits a key MUST leave that field's earlier value; this is how the `message_delta` output count (42 in the tests) replaces the `message_start` count (1).
- **sse-final-line-flush**: On `finish` in streaming mode, any buffered bytes with no trailing newline MUST be processed as one last line.
- **sse-unterminated-line-cap**: In streaming mode, if the buffer still holds more than 4 MiB (4 × 1024 × 1024 bytes) after all complete lines are processed, the reader MUST discard the buffer.
- **json-buffering**: In non-streaming mode the reader MUST append chunks to a buffer and parse nothing until `finish`.
- **json-parse-at-finish**: On `finish` in non-streaming mode the reader MUST parse the buffer as a JSON object and set `model` from `model`, `stopReason` from `stop_reason`, and apply `usage`; a buffer that is not a JSON object MUST leave every field nil.
- **json-size-limit**: In non-streaming mode, if buffering a chunk would make the buffer exceed `jsonLimit` (4 MiB, 4 × 1024 × 1024 bytes; a body of exactly 4 MiB is still buffered), the reader MUST stop buffering, discard what it has, and leave every field nil even if the rest of the body is valid.
- **finish-clears-buffer**: After `finish` in non-streaming mode the buffer MUST be emptied.
- **single-threaded**: The reader is a non-`Sendable` class documented as "Not thread-safe; one per response", so each reader MUST be confined to one thread or task at a time, and a response MUST NOT share a reader with another.
- **no-reset**: The reader MUST NOT offer a reset; reuse for a second response is not supported, and a second response's values would overwrite the first's per the last-write-wins rule.

## Appearance

Not applicable — this is a byte-stream parser, not a visual component.

## States

Not applicable — this is a byte-stream parser, not a visual component; its runtime behavior (accumulating, finished) is described under Behavioral Requirements.

## Accessibility

Not applicable — this is a byte-stream parser, not a visual component.

## Conformance Test Vectors

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

## Edge Cases

- **Empty body**: `finish` with no `consume` MUST leave every field nil in both modes (MUST).
- **No `finish` call in non-streaming mode**: nothing is parsed, so every field stays nil (MUST); only streaming mode produces values from `consume` alone.
- **Non-UTF-8 line**: an invalid line is skipped without affecting later lines (MUST).
- **Non-integer usage value** (a string, a fractional number or a null; the source reads integers with `as? Int`): the field is left as it was (MUST).
- **Missing keys**: a `message_start` with no `usage` or no `model` changes nothing for the missing part (MUST).
- **Boundary**: a JSON body of exactly 4 MiB is buffered and parsed; one byte more overflows (MUST). In streaming mode the cap applies only to a partial line left after processing complete lines, so a large body made of many lines is fine (MUST).
- **Overflow is final**: once a non-streaming body has overflowed, later chunks are ignored and `finish` sets nothing (MUST).
- **Error responses**: an Anthropic error body (an object with `type` "error") parses as a JSON object with no `model`, `stop_reason` or `usage`, so every field stays nil; the reader has no error field (MUST).
- **Mid-stream `error` event**: it has type `error` and is ignored; fields read before it are kept (MUST).
- **Concurrent access**: the class is not thread-safe by its own documentation, and Swift's compiler keeps a non-`Sendable` class inside one isolation domain; callers confine each instance (MUST).
- **Offline or disconnected state**: Not applicable — the reader only sees bytes the caller passes; a truncated stream simply yields whatever was read before the cut.
- **Cancellation and timeouts**: Not applicable — every operation is synchronous.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `streaming` | boolean (init argument) | none (required) | Selects server-sent-event parsing (`true`) or whole-JSON parsing (`false`). |
| `jsonLimit` | integer, internal constant | 4194304 (4 MiB) | Largest non-streaming body buffered, and the cap on an unterminated streaming line. Not caller-settable. |

## Deep Linking

Not applicable: the source defines no URL, route or navigable destination.

## Localization

Not applicable: the reader contains no user-facing string; it reads machine fields from a provider response.

## Accessibility Options

Not applicable: the reader renders nothing and reads no accessibility display setting.

## Feature Flags

Not applicable: the source declares no feature-flag key and contains no conditional gating.

## Analytics

Not applicable: the source contains no analytics or event-emission call; it only exposes values a caller may record.

## Privacy

- **Data collected**: only the model name, four token counts and the stop reason; the reader does not keep message text, tool input or credentials, and discards every other field it parses.
- **Storage**: in memory only, for the life of the instance; the reader writes nothing.
- **Transmission**: None; the reader makes no network call.
- **Retention**: until the instance is released. A non-streaming reader holds up to 4 MiB of raw response body in memory until `finish`, which can contain the full reply text.

## Logging

Not applicable: the reader contains no logging call; a caller records the values it exposes.

## Platform Notes

- **SwiftUI**: not applicable to this file; it imports only `Foundation`. A SwiftUI usage panel would read the six properties after the caller finishes the reader.
- **Compose**: use a Kotlin class with a `StringBuilder` or `ByteArrayOutputStream` buffer, and `kotlinx.serialization.json` `Json.parseToJsonElement` inside a `runCatching` to reproduce never-throws; with OkHttp, tap the response through an interceptor that copies bytes without consuming them.
- **React/Web**: use a class holding a `Uint8Array` or string buffer, split on `"\n"` with a `TextDecoder` configured to stream, and wrap `JSON.parse` in try/catch; check `typeof value === "number" && Number.isInteger(value)` to match the integer-only usage rule. A `fetch` response can be read via `response.clone().body` so the original stream is not altered.
- **AppKit / UIKit**: this is the source. The file is `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AnthropicResponseReader.swift`, a `public final class` with `JSONSerialization` parsing and `Data` buffers; the `jsonLimit` constant is internal (`static let`) and the tests reach it through `@testable import`. Integer reads use `as? Int`, so a JSON number that is not representable as `Int` is skipped.
- **WinUI 3**: use `System.Text.Json` (`JsonDocument.Parse` in a try/catch, or `Utf8JsonReader` for streaming) and a `MemoryStream` or `ArrayBufferWriter<byte>` buffer. Split lines on 0x0A and trim one 0x0D. Use `int?` properties with private setters for the six fields and `JsonElement.TryGetInt32` to match integer-only reads (it rejects decimals and strings). The class is not thread-safe by design, so do not share it across `Task`s without a lock; with `HttpClient`, wrap the response stream in a read-through `Stream` that forwards bytes untouched to the caller while calling the reader.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/AIPluginKit/AnthropicResponseReader.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The reader is passive and never throws; unreadable input leaves fields nil.
**Rationale**: Its doc comment says it reads "for the record", so a recording fault must never break or alter the response the caller is relaying. The cost is that a parse failure and an absent field look the same to a caller.
**Approved**: pending

**Decision**: A non-streaming body over 4 MiB is dropped entirely instead of parsed.
**Rationale**: The source documents "JSON bodies larger than this are not buffered; every field stays nil", bounding memory for a passive observer. A large valid body therefore yields no usage record.
**Approved**: pending

**Decision**: Streaming mode also discards its buffer when an unterminated line exceeds the same 4 MiB.
**Rationale**: The source comment says "A line with no newline for this long is not an event we need." The discard also drops any valid line prefix in the buffer.
**Approved**: pending

**Decision**: The last value read wins for each usage key, and a missing key keeps the earlier value.
**Rationale**: Anthropic reports input counts at `message_start` and the final output count at `message_delta`; the reader merges both into one set of fields. The reader does not sum counts.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`separation-of-concerns` passes because the reader only extracts fields; transport, relaying and recording live elsewhere. `unit-test-coverage` is partial because `AnthropicResponseReaderTests` covers byte-wise streaming, CRLF, whole JSON, garbage in both modes and the JSON size limit, but not the final-line flush, the streaming line cap, the integer-only usage rule or error bodies. `explicit-error-handling` is partial because the reader deliberately signals no failure at all: that is its documented contract ("never throws"), so a malformed body is indistinguishable from an absent field. `data-minimization` passes because only six fields are retained.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
