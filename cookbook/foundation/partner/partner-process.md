---
id: d2213cbb-1a6e-452e-98f0-acd2007c8430
title: "Partner Process"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The partner's claude process seen as typed messages in and out: start, send, a single-consumer stream of decoded stdout, terminate, and stderr text."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - process
  - streaming
depends-on:
  - f333f036-2c23-4a87-8496-bd3616b44786
  - c77c4cfb-e9be-4339-b40d-3f7abc6a4543
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Process

## Overview

`PartnerProcessing` is the protocol and `PartnerProcess` the actor that runs `claude -p --input-format stream-json` over a `SubprocessChannel` and presents it as typed messages: text goes in as stream-json user messages, and stdout comes out as a stream of decoded `ClaudeStreamMessage` values that ends when the process ends. It also reports whether the process is running and what it wrote to stderr, so a crash can be told from a clean end.

## Behavioral Requirements

- **protocol-surface**: `PartnerProcessing` MUST be `Sendable` and offer `start()` (async, throws), `send(_:)` (async, throws), `messages()`, `terminate()` (async), `isRunning` (async) and `standardErrorText()` (async).
- **actor-isolation**: `PartnerProcess` MUST be an `actor`; its `start`, `send`, `terminate`, `isRunning` and `standardErrorText` run serialised on it, and `messages()` MUST be `nonisolated` so it can be called without awaiting.
- **configured-init**: The public initializer MUST take a `PartnerProcessConfiguration` and an environment dictionary, and launch the configuration's `executable` with its `arguments` and its `workingDirectory` as the child's current directory.
- **framing**: The channel MUST use newline-delimited framing, so each stdout line is one message and each input is one line.
- **environment-replace**: The caller's environment MUST be handed over with the replace policy, so a variable the caller removed stays removed, because the caller hands over the child's whole environment; an empty dictionary inherits the parent's environment, which is the channel's documented behavior for that policy.
- **start-launches**: `start()` MUST launch the channel, take its message stream and begin decoding stdout lines; a launch failure MUST propagate as the thrown error.
- **start-once**: A second `start()` MUST throw, because the channel does not allow a second launch.
- **send-user-message**: `send(_:)` MUST write one line made by `ClaudeStreamInput.userMessage(text)` (a JSON object of type `user` with the text as one text block, then a newline) to the process's stdin; a failed write MUST propagate as the thrown error.
- **send-before-start**: `send(_:)` before `start()` MUST throw, because the channel is not launched.
- **decode-each-line**: Each stdout line MUST be decoded with `ClaudeStreamMessage.decode` and yielded in order on the stream.
- **undecodable-skipped**: A line that fails to decode MUST be skipped without ending the stream, and a debug log line `skipped an undecodable stdout line` MUST be written.
- **stream-error-ends**: When reading stdout throws, the failure MUST be logged at debug level and the stream MUST finish; it is not rethrown, so an errored end looks like a clean end on the stream.
- **stream-ends-with-process**: The stream MUST finish when stdout ends, so it ends when the process ends.
- **single-consumer**: The first `messages()` call MUST return the live stream; every later call MUST return an already-finished stream that yields nothing.
- **decode-off-actor**: The pump that decodes stdout MUST be a detached task capturing no actor state, so decoding stays off the actor's executor and the pump does not keep the process alive.
- **terminate**: `terminate()` MUST terminate the channel, wait for the pump to finish, then finish the stream; it MUST leave `isRunning` false.
- **terminate-unstarted**: `terminate()` before `start()` MUST complete without error, because the pump is absent and the channel's terminate is safe before launch.
- **deinit-cleanup**: When the actor is released, it MUST cancel the pump and terminate the channel from a detached task.
- **is-running**: `isRunning` MUST report the channel's state.
- **stderr-text**: `standardErrorText()` MUST return what the process wrote to stderr so far, for telling a crash from a clean end; it returns the channel's stderr text, and the channel's own stderr requirement decides how much is kept and how it is decoded.
- **buffering**: The stream MUST use the default unbounded buffer, so messages decoded before a consumer exists are kept until it reads them.

## Appearance

Not applicable — this is a process wrapper that exchanges typed messages, not a visual component.

## States

Not applicable — this is a process wrapper that exchanges typed messages, not a visual component.

## Accessibility

Not applicable — this is a process wrapper that exchanges typed messages, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-process-001 | start-launches, decode-each-line, send-user-message, stream-ends-with-process, terminate, is-running | Process of `/bin/cat` with no arguments and an empty environment; `start()`; check `isRunning`; read `messages()` in a task; `send("x")`; wait 300 ms; `terminate()`. | `isRunning` is true after start and false after terminate; the stream finishes within 10 seconds; the first message has kind `user` and its first block text is `x` (test: catEchoDecodesAndTerminateEndsTheStream). |
| partner-process-002 | single-consumer | A started process; call `messages()` once and discard, then iterate the second call's stream. | The second stream yields 0 messages and finishes (test: secondMessagesCallReturnsAFinishedStream). |
| partner-process-003 | undecodable-skipped, stream-ends-with-process | Process of `/bin/echo` with the argument `not json`; `start()`; iterate `messages()`. | 0 messages and the stream finishes (test: undecodableLinesAreSkipped). |
| partner-process-004 | decode-each-line | Process of `/bin/echo` with the argument `{"type":"result","subtype":"success","is_error":false,"result":"ok","session_id":"s"}`; `start()`; iterate. | One message of kind `result` with `resultText` `ok` (test: resultLineDecodes). |
| partner-process-005 | send-before-start | A process never started; `send("x")`. | Throws a not-launched error. |
| partner-process-006 | start-once | A started process; call `start()` again. | Throws an already-launched error. |
| partner-process-007 | start-launches | Executable path that does not exist; `start()`. | Throws the channel's launch failure. |
| partner-process-008 | terminate-unstarted | A process never started; `terminate()`. | Returns without error; `isRunning` is false. |
| partner-process-009 | stderr-text | A started process of `/bin/sh` that writes `boom` to stderr and exits; after the stream ends call `standardErrorText()`. | The text contains `boom`. |
| partner-process-010 | framing, send-user-message | Process of `/bin/cat`; `start()`; read `messages()` in a task; `send("a")` then `send("b")`; wait 300 ms; `terminate()`. | Two messages of kind `user`, in order, with first-block texts `a` then `b`. |
| partner-process-011 | environment-replace | Process of `/bin/sh` with arguments `-c` and a script that echoes one `result` JSON line whose `result` is `$FOO-${BAR-unset}`; environment `FOO` `a` and `PATH` `/bin:/usr/bin` only; the parent has `BAR` set. | One message of kind `result` with `resultText` `a-unset`. |
| partner-process-012 | buffering | Process of `/bin/cat`; `start()`; `send("x")`; wait 300 ms; only then call `messages()` for the first time and read it. | The first message has kind `user` and text `x`, so the message decoded before any consumer existed was kept. |
## Edge Cases

- **Null / empty input**: An empty string to `send(_:)` is written as a user message with an empty text block; nothing rejects it. A configuration with no `workingDirectory` cannot be built through the public initializer, because the field is a required string.
- **Boundary values**: A stdout line that is valid JSON but not an object, or not JSON, fails to decode and is skipped (MUST). A line of a type the decoder does not know decodes to the `other` kind and is yielded.
- **Consumer breaks out of the stream**: The consumer of `messages()` should not `break` out of the stream, because the source documents that doing so ends the stream for good; the stream is single-consumer, so there is no second consumer to take over.
- **Concurrent access**: Actor members are serialised. `messages()` is `nonisolated` and guards its hand-out flag with an unfair lock, so two concurrent first calls cannot both receive the live stream.
- **Error states**: A launch failure and a failed or broken-pipe write surface as thrown errors from `start()` and `send(_:)`. A stdout read error is only logged and finishes the stream; a crash is told from a clean end by `standardErrorText()` and by `isRunning`, not by the stream.
- **Offline / disconnected state**: Not applicable: the process is local and the type performs no network access; whether `claude` reaches its service is outside this type.
- **Cancellation**: Cancelling a consumer task does not stop the process. `terminate()` is the way to stop it, and releasing the actor also terminates it; a consumer that breaks out of the stream ends it for good; the pump keeps draining stdout, but its messages are dropped.
- **Process exits on its own**: The stream finishes; `isRunning` becomes false; later `send(_:)` calls fail on the closed pipe.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` | `PartnerProcessConfiguration` | none, required | Supplies the executable, arguments and working directory (see Partner Process Configuration ([adhsdk.ingredient.foundation.partner.partner-process-configuration](cookbook:c77c4cfb-e9be-4339-b40d-3f7abc6a4543))). |
| `environment` | `[String: String]` | none, required | The child's whole environment under the replace policy; an empty dictionary inherits the parent's. |
| framing | fixed | newline-delimited | One JSON object per line in both directions. |
| stream buffer | fixed | unbounded | The default `AsyncStream` buffering policy. |

## Deep Linking

Not applicable: it defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the only strings are debug log messages for developers, not user-facing text.

## Accessibility Options

Not applicable: it presents no UI, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: The conversation text sent on stdin, the decoded messages from stdout, the stderr text, and the environment the caller passes, which can hold credentials.
- **Storage**: None by this type; the channel keeps stderr text in memory for `standardErrorText()`.
- **Transmission**: Over local pipes to the `claude` process only; what that process sends onward is outside this type.
- **Retention**: In-memory until the actor and channel are released.

## Logging

Subsystem: `AgenticDeveloperHubSDK` | Category: `PartnerProcess`

| Event | Level | Message |
|-------|-------|---------|
| A stdout line fails to decode | debug | `skipped an undecodable stdout line` |
| Reading stdout throws | debug | `stdout ended with an error: <error description>` |

The error description is interpolated without a privacy annotation, so the platform's default redaction applies.

## Platform Notes

- **SwiftUI**: This is the Swift core implementation note and nothing in it is UI-specific. It imports `Foundation` and `os`, and is an `actor` over `SubprocessChannel`, using `AsyncStream.makeStream`, `OSAllocatedUnfairLock` and a detached `Task`; a view model awaits the stream. A second, internal initializer takes the executable, arguments, environment and an optional working directory directly, for tests.
- **Compose**: A Kotlin class over `ProcessBuilder` with a coroutine reading `stdout` lines into a `Channel` or `Flow`; use a `Mutex` or a single-threaded dispatcher for the actor serialisation and an `AtomicBoolean` for the single-consumer hand-out. `ProcessBuilder.environment().clear()` gives the replace policy.
- **React/Web**: Node's `child_process.spawn` with `readline` over stdout and an async iterator; Node is single-threaded, so the hand-out flag needs no lock. Browsers cannot launch processes.
- **AppKit / UIKit**: On AppKit the SwiftUI note applies unchanged, using `Process` and pipes. UIKit on iOS cannot launch a subprocess, so an iOS port of this type has no implementation and must talk to a process hosted elsewhere.
- **WinUI 3**: A C# class around `System.Diagnostics.Process` with `RedirectStandardInput`, `RedirectStandardOutput` and `RedirectStandardError`; read lines with `StreamReader.ReadLineAsync` into a `System.Threading.Channels.Channel<ClaudeStreamMessage>` (single reader), serialise `Start`, `Send` and `Terminate` with a `SemaphoreSlim`, and set `ProcessStartInfo.WorkingDirectory`. Call `ProcessStartInfo.Environment.Clear()` before copying in the caller's values for the replace policy, but only when the caller's dictionary is not empty, because the Swift channel inherits the parent's environment for an empty one. Termination needs `Process.Kill(entireProcessTree: true)` for grandchildren, which the Swift channel documents it does not reap. Decode with `System.Text.Json.JsonDocument` and skip a line when parsing throws `JsonException`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerProcess.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `messages()` is single-consumer and later calls get a finished stream.
**Rationale**: The stream wraps one stdout reader; two consumers would split the messages between them, so the second call is made harmless instead.
**Approved**: pending

**Decision**: An undecodable stdout line is skipped and logged at debug level.
**Rationale**: A stray non-JSON line, such as a warning, should not end the conversation; the cost is that a malformed message is silent apart from the debug log.
**Approved**: pending

**Decision**: The pump is detached and captures no actor state.
**Rationale**: The process must not be kept alive by its own reader, and decoding stays off the actor so a slow decode does not block `send` or `terminate`.
**Approved**: pending

**Decision**: The caller's environment is applied with the replace policy.
**Rationale**: The caller hands over the child's whole environment, so a variable it removed stays removed rather than being re-inherited; this is the replace policy of the channel the process runs over.
**Approved**: pending

**Decision**: A stdout read error finishes the stream rather than throwing from it.
**Rationale**: The `AsyncStream` type has no error channel; the consumer learns the cause from `standardErrorText()` and `isRunning`. The alternatives weighed are an `AsyncThrowingStream`, which would carry the error but make every consumer handle a throw, and a terminal `ended(reason)` message value, which would carry the reason in-band but change the message type; neither was chosen, so this decision stays pending.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | Reliability |

`separation-of-concerns` passes because spawning, framing and pipes are the `SubprocessChannel`'s, line decoding is `ClaudeStreamMessage`'s and launch arguments are `PartnerProcessConfiguration`'s; this type only joins them. `unit-test-coverage` passes: `PartnerProcessConformanceTests` runs real processes (`/bin/cat`, `/bin/echo`, `/bin/sh`) and covers all 12 vectors, including send-before-start, start-once, launch failure, terminate-unstarted, the stderr text, ordering, environment replacement and buffering. `error-recovery` is partial: a read error ends the stream with a debug log only, and nothing restarts the process.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerProcessConformanceTests.swift, 12 of 12 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Marked test coverage partial, pointed stderr text at the channel, added a stream-end alternatives discussion and framing, environment and buffering vectors, links to its ingredients, and moved caller and internal-API text out of requirements. |
