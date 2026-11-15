---
id: 29db699c-56f4-40da-a8f7-b96a0cf820b0
title: "Partner Chat Session"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A chat session over the partner process: folds decoded stream messages and owner lines into chat events and a transcript, and reports which assistant replies to persist."
platforms:
  - swift
  - macos
tags:
  - partner
  - chat
  - session
  - stream
depends-on:
  - f333f036-2c23-4a87-8496-bd3616b44786
related:
  - d2213cbb-1a6e-452e-98f0-acd2007c8430
references: []
approved-by: ""
approved-date: ""
---

# Partner Chat Session

## Overview

`PartnerChatSession` is the `ChatSession` implementation that fronts the partner process (a long-running Claude Code process driven over its stream-json output). It does not own that process. The partner controller feeds it each decoded `ClaudeStreamMessage` (see Claude Stream JSON ([adhsdk.ingredient.foundation.partner.claude-stream-json](cookbook:f333f036-2c23-4a87-8496-bd3616b44786))) through `apply`, feeds it the owner's own lines through `noteUserMessage`, and sets its lifecycle state through `setState`. The session turns those inputs into a single stream of `ChatEvent` values for a chat UI and returns, from `apply`, the assistant `ChatMessage` values the caller should persist. User turns typed into the chat go out through an injected send closure; interruption goes out through an injected interrupt closure. The type holds an in-memory transcript and nothing else about the conversation.

## Behavioral Requirements

Construction and transcript

- **transcript-seed**: The session MUST start with the `initial` messages passed to its initializer as its transcript, in the given order.
- **transcript-grows-by-owner-lines**: The session MUST append each message passed to `noteUserMessage` to the end of its transcript.
- **transcript-grows-by-assistant-text**: The session MUST append each assistant reply it creates in `apply` to the end of its transcript.
- **transcript-never-cleared**: `clear()` MUST be a no-op: the session MUST leave its transcript unchanged when it is called.

Event stream

- **event-payloads**: The events the session emits MUST carry these payloads: `.transcriptLoaded([ChatMessage])`, `.userMessage(ChatMessage)`, `.stateChanged(ChatSessionState)`, `.responseStarted(messageID)`, `.responseDelta(messageID, text)`, `.toolCall(messageID, name, phase)` with phase `.started` or `.completed`, `.responseFinished(messageID, stopReason)` and `.turnFailed(ChatError)`, where `messageID` is a string id and `ChatError` carries a `message` and an `isRetryable` flag.
- **events-replay-transcript**: Each stream returned by `events()` MUST yield `.transcriptLoaded` carrying the transcript as it stood at the moment of the call as its first event.
- **events-single-subscriber**: A call to `events()` MUST finish the stream returned by the previous call, so that only the newest stream receives later events.
- **events-no-buffer-without-subscriber**: An event emitted while no stream is attached (before the first `events()` call, or after `close()`) MUST NOT be buffered or replayed; only the transcript is replayed to a new stream.
- **state-not-replayed**: A stream MUST NOT receive the state set by an earlier `setState` call; a new stream sees `.transcriptLoaded` followed only by later events.
- **events-never-throw**: The stream MUST report a failed turn as `.turnFailed` and keep the stream open, never by ending the stream with an error.

Outbound and lifecycle operations

- **send-forwarding**: `send(_:)` MUST call the injected send closure exactly once with the text unchanged.
- **send-no-local-effect**: `send(_:)` MUST NOT append to the transcript and MUST NOT emit an event; the owner's line enters the transcript only through `noteUserMessage`.
- **interrupt-forwarding**: `interrupt()` MUST call the injected interrupt closure exactly once.
- **close-signals-closed**: `close()` MUST yield `.stateChanged(.closed)` to the attached stream and then finish that stream.
- **close-detaches**: After `close()`, the session MUST hold no stream, so later events are dropped until `events()` is called again.
- **close-without-stream-silent**: `close()` with no attached stream MUST emit nothing.
- **use-after-close**: After `close()` the session MUST keep accepting `apply`, `noteUserMessage` and `setState` without failing; their events go to no stream until a new one is attached by `events()`.
- **close-keeps-transcript**: `close()` MUST NOT modify the transcript.
- **note-user-message**: `noteUserMessage(_:)` MUST append the message to the transcript and then emit `.userMessage` carrying that message.
- **set-state-emits**: `setState(_:)` MUST emit `.stateChanged` carrying the given `ChatSessionState` to the attached stream.

Folding stream messages (`apply`)

- **apply-returns-persistable**: `apply` MUST return the assistant `ChatMessage` values it appended during that call, in block order, and MUST return an empty array for every message that appended none.
- **assistant-text-block**: For each assistant block of kind `.text` whose text is non-nil and non-empty, `apply` MUST create one `ChatMessage` with role `.assistant` and that text.
- **assistant-text-events**: For each such reply, `apply` MUST emit `.responseStarted`, then one `.responseDelta` carrying the whole text, then `.responseFinished` with `stopReason` nil, all with the reply's message id.
- **assistant-empty-text-skipped**: `apply` MUST skip an assistant text block whose text is nil or empty: no message, no event.
- **assistant-current-id**: `apply` MUST record the id of the newest assistant reply as the current assistant message id.
- **tool-use-started**: For each assistant block of kind `.toolUse`, `apply` MUST emit `.toolCall` with phase `.started`, the block's name (or `"tool"` when the name is nil), and the current assistant message id.
- **tool-name-registry**: When a `.toolUse` block has both an `id` and a `name`, `apply` MUST remember the name under that id for later tool results; a block missing either MUST NOT be remembered.
- **assistant-other-blocks-ignored**: `apply` MUST ignore assistant blocks of any kind other than `.text` and `.toolUse` (thinking, tool result, other).
- **tool-result-completed**: For each block of kind `.toolResult` in a message of kind `.user`, `apply` MUST emit `.toolCall` with phase `.completed`, the name remembered for the block's `toolUseID` (or `"tool"` when the id is nil or unknown), and the current assistant message id.
- **user-other-blocks-ignored**: `apply` MUST emit nothing for a `.user` message's blocks of any kind other than `.toolResult`, and MUST return an empty array; this is why the owner's replayed line produces no event.
- **fresh-message-id**: When a tool event is emitted and no current assistant message id exists, the session MUST mint a new globally unique string identifier, keep it as the current id, and reuse it for later tool events in the same turn; no `.responseStarted` is emitted for that id.
- **result-ends-turn**: For a message of kind `.result`, `apply` MUST clear the current assistant message id.
- **result-failure-text**: When a `.result` has `isError` true, `apply` MUST emit `.turnFailed` carrying a `ChatError` whose message is the first available of `resultText`, `subtype`, and the literal `"error"`.
- **result-failure-retryable**: The `ChatError` emitted for an error `.result` MUST have `isRetryable` true.
- **result-ready**: For every `.result`, error or not, `apply` MUST emit `.stateChanged(.ready)` after any `.turnFailed`.
- **system-init-and-other-ignored**: `apply` MUST emit nothing and return an empty array for messages of kind `.systemInit` and `.other`.

Concurrency

- **lock-guarded-state**: The session MUST guard its transcript, attached stream, tool-name registry and current assistant message id with one lock so that any thread may call any operation. The type is `@unchecked Sendable` for this reason, and the send and interrupt closures are `@Sendable`.
- **yield-outside-lock**: The session MUST deliver events to the stream after releasing the lock, so a consumer's work never runs while the lock is held.
- **cross-thread-event-order**: Callers MUST NOT rely on the order of events across threads: the session does not make a state change and its matching event one atomic step, so when two threads call it at once, the order of their events on the stream is the order in which each call reaches its yield, not necessarily the order in which their changes were applied to the transcript. The partner controller, which is `@MainActor`, is the only caller of `apply`, `noteUserMessage` and `setState` in the source, so in practice those calls are serialised by the main actor.

## Appearance

Not applicable — this is a headless session object that turns messages into events, not a visual component.

## States

Not applicable — this is a headless session object, not a visual component. The runtime state is carried by `ChatSessionState` (`connecting`, `ready`, `responding`, `failed`, `closed`), which this type does not store: it emits whatever its owner sets with `setState`, plus `.ready` after each `.result` and `.closed` from `close()`.

## Accessibility

Not applicable — this is a headless session object, not a visual component.

## Conformance Test Vectors

Vectors 001 to 005 are the cases asserted in `PartnerChatSessionTests` (named in the Input column); vectors 006 onward are derived from the `PartnerChatSession` source and are asserted by tests whose display names carry the vector id, except 022, which needs a Thread Sanitizer run.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-chat-session-001 | assistant-text-block, assistant-text-events, apply-returns-persistable | Subscribe, then `apply` an assistant message with one text block "hello" (`assistantTextBecomesAStreamedMessage`) | Returns one `.assistant` message with text "hello"; the stream carries a `.responseDelta` whose text is "hello" |
| partner-chat-session-002 | tool-use-started, tool-name-registry, tool-result-completed | Subscribe; `apply` an assistant toolUse block (name "n", id "t1"); then `apply` a user message with a toolResult block (toolUseID "t1") (`toolUseThenToolResultEmitStartedAndCompleted`) | Events include `.toolCall(_, "n", .started)` and `.toolCall(_, "n", .completed)` |
| partner-chat-session-003 | result-failure-text, result-failure-retryable, result-ready | Subscribe; `apply` a `.result` with isError true, subtype "error_max_turns", resultText "boom" (`errorResultEmitsTurnFailedAndReadyState`) | After the leading `.transcriptLoaded`, the next event is `.turnFailed(ChatError(message: "boom", isRetryable: true))` and the one after is `.stateChanged(.ready)` |
| partner-chat-session-004 | transcript-seed, events-replay-transcript | Session created with one earlier user message; first event of `events()` (`initialTranscriptIsReplayedOnSubscribe`) | First event equals `.transcriptLoaded` with that message |
| partner-chat-session-005 | user-other-blocks-ignored, note-user-message | Subscribe; `apply` a `.user` message with one text block "hi", then `noteUserMessage` with a user message "hi" (`ownerEchoProducesNothingAndUserNoteEmits`) | `apply` returns an empty array and emits nothing; the event after the leading `.transcriptLoaded` equals `.userMessage` with the noted message |
| partner-chat-session-006 | send-forwarding, send-no-local-effect | Session with a recording send closure; call `send("go")` | Closure called once with "go"; transcript unchanged; no event after `.transcriptLoaded` |
| partner-chat-session-007 | interrupt-forwarding | Call `interrupt()` | Interrupt closure called once; no event emitted |
| partner-chat-session-008 | close-signals-closed, close-detaches, close-keeps-transcript | Subscribe; call `close()`; then `apply` an assistant text block | Stream yields `.stateChanged(.closed)` then ends; the later events reach no stream; the transcript still holds the reply |
| partner-chat-session-009 | close-without-stream-silent | Call `close()` twice with one stream attached | Second call emits nothing and does not fail |
| partner-chat-session-010 | events-single-subscriber | Call `events()` twice, then `noteUserMessage` | First stream ends; only the second stream receives `.userMessage` |
| partner-chat-session-011 | events-no-buffer-without-subscriber, state-not-replayed | Call `setState(.responding)` and `noteUserMessage` with no stream attached, then call `events()` | The new stream's first event is `.transcriptLoaded` containing the noted message; no `.stateChanged(.responding)` is delivered |
| partner-chat-session-012 | assistant-empty-text-skipped | `apply` an assistant message with text blocks "" and nil | Returns empty; transcript and stream unchanged |
| partner-chat-session-013 | assistant-text-block, apply-returns-persistable | `apply` an assistant message with text blocks "a" and "b" | Returns two messages in order; three response events per message; transcript has both |
| partner-chat-session-014 | tool-result-completed | `apply` a user toolResult block whose toolUseID was never registered, and one with a nil toolUseID | Each emits `.toolCall` with name "tool" and phase `.completed` |
| partner-chat-session-015 | tool-name-registry, tool-use-started | `apply` an assistant toolUse block with a name but no id | Emits `.toolCall` started with that name; a later toolResult cannot resolve it and reports "tool" |
| partner-chat-session-016 | fresh-message-id, result-ends-turn | `apply` a toolUse block with no earlier text, then another toolUse, then a `.result`, then another toolUse | The first two events share one UUID-string id with no `.responseStarted`; after the result the next tool event carries a different id |
| partner-chat-session-017 | result-failure-text | `apply` an error `.result` with resultText nil and subtype "error_max_turns"; then one with both nil | Messages are "error_max_turns" and "error" |
| partner-chat-session-018 | result-ready | `apply` a `.result` with isError false | Only `.stateChanged(.ready)` is emitted |
| partner-chat-session-019 | system-init-and-other-ignored, assistant-other-blocks-ignored | `apply` a `.systemInit` message, an `.other` message and an assistant message holding only a thinking block | All return empty and emit nothing |
| partner-chat-session-020 | transcript-never-cleared | Add a noted message, call `clear()`, then call `events()` | First event is `.transcriptLoaded` with the message still present |
| partner-chat-session-021 | set-state-emits | Subscribe, call `setState(.responding)` | Stream yields `.stateChanged(.responding)` |
| partner-chat-session-022 | lock-guarded-state, yield-outside-lock | Call `noteUserMessage` from many tasks while a consumer reads the stream | Run under Thread Sanitizer: no data race is reported, and exactly one `.userMessage` per call is delivered |
| partner-chat-session-023 | result-failure-text | `apply` an error `.result` with resultText nil, subtype nil and errors ["x"] | Message is "error", not "x" |
| partner-chat-session-024 | events-never-throw | `apply` an error `.result`, then `noteUserMessage` | Stream stays open and delivers the later `.userMessage` |
| partner-chat-session-025 | transcript-grows-by-owner-lines, transcript-grows-by-assistant-text | `noteUserMessage` then an assistant text `apply`; open a new stream | `.transcriptLoaded` holds both messages in call order when the calls are made from one thread |

## Edge Cases
- **Empty or missing text**: A skipped empty text block and a nameless tool block follow `assistant-empty-text-skipped` and `tool-use-started`.
- **Unknown tool result**: A tool result whose id was never seen, or has no id, follows `tool-result-completed`. The tool-name registry is never pruned, so it grows by one entry per distinct tool id for the life of the session; the Design Decision on the registry accepts that.
- **Events before a subscriber**: Anything emitted before `events()` is called is lost, apart from the transcript (`events-no-buffer-without-subscriber`, `events-replay-transcript`). Callers that need every event subscribe before applying messages, as the tests do.
- **Second subscriber**: See `events-single-subscriber`.
- **Use after close**: See `use-after-close`; `close()` does not make the session reject later calls.
- **Error result with no text**: See `result-failure-text`. An error `.result` whose only detail is in `errors` reports `"error"`: that array is deliberately not read (see the Design Decision on error results), which loses information but still surfaces a failure.
- **Result without error**: A `.result` with `isError` false emits no `.turnFailed` (`result-failure-text`, `result-ready`).
- **Partial turns**: A tool event before any assistant text uses a minted id with no `.responseStarted` (`fresh-message-id`); a consumer that builds one row per `.responseStarted` will not have a row for that id.
- **Streaming granularity**: Each text block arrives as one start, one delta and one finish with `stopReason` nil (`assistant-text-events`). The `ChatMessage` this type returns and stores always has `isStreaming` false; a consumer folding the events with `ChatTranscriptReducer` sees it true only between the started and finished events, which the session emits back to back.
- **Concurrent calls**: Calls from several threads are safe for the guarded state (`lock-guarded-state`); the relative order of their events is not defined (see `cross-thread-event-order`).
- **Network, timeouts, retry, offline**: Not applicable: the session performs no I/O. The send and interrupt closures own delivery to the process; this type adds no timeout, retry or cancellation of its own.
- **Boundary values**: Not applicable beyond the empty cases above: there are no numeric inputs or limits.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `initial` | array of `ChatMessage` | none (required) | Transcript the session starts with and replays to each new stream |
| `send` | `@Sendable` closure taking a string | none (required) | Called by `send(_:)` with the owner's text; this type does not echo it |
| `interrupt` | `@Sendable` closure with no arguments | none (required) | Called by `interrupt()` |

## Deep Linking

Not applicable: the session is a headless object with no URL surface; nothing in the source routes by URL.

## Localization

The session produces two hardcoded English fallback strings that reach the UI, and no externalised strings. A port keeps the literals unless its owner localises them.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | `tool` | Tool name shown when a tool event has no name or an unknown id |
| none (literal) | `error` | Failure text when an error result has neither `resultText` nor `subtype` |

## Accessibility Options

Not applicable: the session is headless and renders nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach it.

## Feature Flags

Not applicable: the source reads no flag; behavior is fixed.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: The conversation text (owner lines and assistant replies) and tool names, held in memory in the transcript.
- **Storage**: In memory only. The type persists nothing; it returns the assistant replies from `apply` so the caller can persist them, and the caller persists owner lines itself.
- **Transmission**: The type transmits nothing itself; owner text leaves only through the injected send closure.
- **Retention**: Until the instance is released. `close()` does not clear the transcript.

## Logging

Not applicable: the source makes no log call. A failed turn is reported as a `.turnFailed` event, not logged.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerChatSession.swift`, in the `AgenticDeveloperHubSDKCore` framework, importing only `Foundation`. A SwiftUI view model folds `events()` (with `ChatTranscriptReducer`) into `@Published` state; this type is not itself observable. The fresh message id is `UUID().uuidString`. It conforms to `ChatSession` and is `@unchecked Sendable` with an `NSLock`, and `events()` builds an `AsyncStream` whose continuation it swaps under that lock. Tests are `PartnerChatSessionTests` in the Core test target.
- **Compose**: Hold one `Channel<ChatEvent>` that `events()` replaces on each call: close the previous channel, create a new one, seed it with the transcript snapshot and return it as a `Flow` with `receiveAsFlow()`. Events sent while no channel is attached are dropped, which matches "no buffering without a subscriber". Keep the transcript in a `mutableStateListOf` or guard it with a `Mutex`.
- **React/Web**: Model it as a small class with an `EventTarget` or a single subscribed callback; `events()` replaces the previous callback and invokes the new one first with the transcript. JavaScript is single-threaded, so the lock and the cross-thread ordering concern disappear; the send and interrupt closures become constructor callbacks. Fold the events with a `useReducer` or an external store read through `useSyncExternalStore`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the type is UI-framework agnostic. An `NSViewController` subscribes with a `Task` that iterates the stream on the main actor. In the source the owner is the `@MainActor` `PartnerController`, which calls `apply`, `noteUserMessage` and `setState` from the main actor.
- **WinUI 3**: Implement as a class with a lock (`lock` statement or `SemaphoreSlim`) around the transcript, tool-name `Dictionary<string, string>`, current id and one `System.Threading.Channels.Channel<ChatEvent>`; `events()` completes the previous channel's writer, creates a new unbounded channel, seeds it with the transcript snapshot and returns its `ChannelReader` consumed with `await foreach` (`IAsyncEnumerable`). Events written with no channel attached are dropped, as in the source. Use `Guid.NewGuid().ToString()` for the fresh id. Bind the UI to an `ObservableCollection` updated on the `DispatcherQueue` from the consumer loop. The type has no Windows storage dependency.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerChatSession.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The session replays only the transcript to a new subscriber, never the current state or any missed event.
**Rationale**: The source emits through the attached continuation only; the owner of the session sets state after attaching, and the transcript is the one thing a late UI needs to rebuild a view. Dropping other events keeps memory bounded when no UI is attached.
**Approved**: pending

**Decision**: `events()` replaces the previous subscriber instead of supporting several.
**Rationale**: The protocol documents one long-lived stream to subscribe once; the source finishes the old continuation so a re-created chat view cannot leave a stale stream running.
**Approved**: pending

**Decision**: A whole text block is emitted as one started, one delta, one finished, with `stopReason` nil.
**Rationale**: The partner process delivers complete assistant messages rather than token streams, and the source projects them into the streaming event shape the chat UI already understands; the stop reason is not carried.
**Approved**: pending

**Decision**: An error result is always reported as retryable, and only `resultText` or `subtype` becomes the message.
**Rationale**: The source marks every failed partner turn retryable, since the next turn can run again; the `errors` array and `numTurns` on the stream message are not read. This is a lossy but surfaced projection, and a port that also reads `errors` is a change to this decision, not a conformance failure.
**Approved**: pending

**Decision**: A tool event with no current assistant message id mints a fresh one rather than being dropped.
**Rationale**: Tool calls can precede any assistant text in a turn; a minted id lets the UI show the call, at the cost of an id with no started event.
**Approved**: pending

**Decision**: `clear()` is not overridden and therefore does nothing; the session is cleared by creating a new instance.
**Rationale**: The partner transcript is the owner's standing record, and the source inherits the protocol's default `clear()`, which does nothing.
**Approved**: pending


**Decision**: The tool-name registry is never pruned, and its growth is accepted.
**Rationale**: The source adds one entry per distinct tool id and removes none, not even on `.result`. Entries are short strings and a partner session is long-lived but handles a bounded number of tool calls per day, so the growth is small; pruning on `.result` would risk dropping a name that a late tool result still needs.
**Approved**: pending

**Decision**: The fallback strings `tool` and `error` stay hardcoded English, and the failed `no-hardcoded-strings` check is accepted.
**Rationale**: They are last-resort labels for a tool event with no name and an error result with no text, in a view for the owner of a developer tool; the source has no string table to localise them through.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The session separates concerns well: it owns no process, no persistence and no view, and takes its outbound behavior as closures. `unit-test-coverage` is partial: `AgenticDeveloperHubSDKCoreTests/Partner/PartnerChatSessionTests.swift` covers vectors 001 to 021 and 023 to 025, and skips vector 022, which needs a Thread Sanitizer run that a unit test cannot detect. A failed turn is surfaced as `.turnFailed`, so error handling is explicit. The fallback strings `tool` and `error` are hardcoded English that can reach the UI, which fails the hardcoded-strings check.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerChatSessionTests.swift, 24 of 25 vectors; 022 skipped, needs Thread Sanitizer); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved the lossy errors rule out of the requirements, added event payloads and use-after-close, renamed the close requirement, linked claude-stream-json and partner-process, accepted registry growth and the hardcoded fallbacks as decisions, and made the Compose note and event-order wording single-answer. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
