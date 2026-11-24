---
id: 00ef3e01-de2f-4f48-bd3c-86f15fb4f72b
title: "Terminal Chat Session"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A chat session whose other side is a shell: lines are typed into a terminal and what it prints back arrives as replies, for a person or another agent."
platforms:
  - swift
  - macos
tags:
  - terminal
  - terminal-chat
  - chat
depends-on:
  - 6e81fe86-b97d-4af9-a45b-0ace8784fbed
  - b71b349b-5c60-41f4-b664-49085ac5d988
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Chat Session

## Overview

`TerminalChatSession` is a main-actor chat session whose other side is a shell. A line sent to it is typed into a connected terminal session, and what the terminal prints back arrives as a reply in the chat's event stream. It changes nothing on the way in or out: it types what was written and reports what the screen shows. A terminal that keeps its contents private does so itself, so its screen, and so every reply read off it, is already what the user is meant to see.

What is lost against typing into the terminal is everything interactive: tab completion, a line editor, a full-screen program. None of it goes through the chat, and output drawn on the alternate screen is not reported.

The session serves two kinds of caller. A person reads the transcript and types into the composer, through the chat-session contract (`events`, `send`, `interrupt`, `close`). A program, such as `adterm` through the control server or a persona's terminal tool, calls `run`, `waitForOutput`, `interruptAndWait` and `screen`, each of which hands back a string. Output is reported once it has been quiet for a short period, or once it has waited a maximum latency, and new output is found by comparing the terminal's screen against a tracker of what has already been reported ([adhsdk.ingredient.foundation.terminal.terminal-output-tracker](cookbook:6e81fe86-b97d-4af9-a45b-0ace8784fbed)). The default settle, timeout, interrupt timeout and line count come from [adhsdk.ingredient.foundation.terminal.terminal-chat-control](cookbook:b71b349b-5c60-41f4-b664-49085ac5d988).

## Behavioral Requirements

- **terminal-weak**: The session MUST hold its terminal weakly, so a closed pane's terminal is not kept alive by the chat.
- **initial-state**: Subscribing to the event stream MUST yield a ready state first, then any events held from before anyone listened, in order, and MUST never report a responding state, because a shell has no turns.
- **unsent-events**: Replies and the exit text produced before the stream is subscribed MUST be kept and handed over once on subscription. The user message and failed turn that `send(_:)` emits are written straight to the stream and are not held: with no subscriber they are lost.
- **connect-replace**: `connect(to:)` MUST replace the current terminal, release the old terminal's output and exit subscriptions and cancel pending report timers.
- **connect-same**: `connect(to:)` with the terminal already connected MUST do nothing, and with nil when already disconnected MUST change nothing.
- **connect-initial-output**: On connecting, what the terminal has already printed MUST be reported at once as the first reply, so the chat opens on what the terminal shows, and that reply MUST NOT be taken as an answer by any waiting caller.
- **connect-drops-input**: Connecting to a new terminal MUST drop input still queued for the old one; disconnecting (nil) MUST let queued input finish in the old terminal.
- **output-report-quiet**: Terminal output MUST be reported as one reply once it has been quiet for the quiet period (300 ms by default), with the timer restarted by each new output.
- **output-report-latency**: Terminal output that keeps arriving MUST be reported once the maximum latency (1 s by default) has passed since the first unreported output, so a stream that never pauses still reaches the transcript.
- **reply-events**: Each report MUST be emitted as a started event, one delta with the whole text and a finished event under one new message id, with no stop reason.
- **no-empty-reply**: A report MUST emit nothing when the tracker finds no new output.
- **send-user-message**: `send(_:)` MUST first emit the text as a user message, as written.
- **send-not-connected**: `send(_:)` with no terminal MUST emit a non-retryable failed turn "Not connected to a terminal." and type nothing.
- **send-typed-text**: `send(_:)` MUST type the text into the terminal with each newline replaced by a carriage return, so a multi-line message goes in as several lines the way a paste would.
- **send-return-separate**: `send(_:)` MUST write Return as a separate write after the return delay (250 ms by default), never inside the text write, so a program that reads keystrokes sees a key press.
- **send-empty**: `send(_:)` with empty text MUST write only the Return.
- **send-order**: Messages MUST be typed in the order sent, each one's Return before the next one's text, even when sent quickly.
- **send-echo**: The session MUST tell the tracker the last line of the text as the terminal presents it, so the shell's echo of that line is left out of the next reply.
- **send-closes-target**: Text already typed MUST get its Return in the terminal it was typed into, even after the chat has closed or connected to another terminal, so a command is never left typed but not run.
- **interrupt**: `interrupt()` MUST drop queued messages not yet typed, MUST drop the Return of text already typed and MUST send Control-C to the terminal.
- **close**: `close()` MUST disconnect, finish the event stream and release it.
- **run-not-connected**: `run`, `waitForOutput` and `interruptAndWait` with no terminal MUST return "The Terminal Chat is not connected to a terminal."
- **run-reply**: `run(_:settle:timeout:)` MUST send the text as `send(_:)` does and return the output reported until output has been quiet for the settle time.
- **run-armed-late**: A run MUST NOT count its settle or timeout until its Return has been written, so the echo of the text alone cannot settle the wait early and the timeout counts from the Return.
- **run-fresh**: A run MUST start its wait empty, not with earlier unclaimed output.
- **wait-replay**: `waitForOutput` MUST start with the output reported since the last caller stopped listening, then collect what arrives until the output has been quiet for the settle time.
- **interrupt-wait**: `interruptAndWait` MUST begin its wait before sending Control-C, start it empty and default its timeout to the interrupt timeout (10 s).
- **wait-single**: Only one wait MUST be active; beginning a new wait MUST end the previous one with what it had.
- **wait-settle-cap**: A wait's settle time MUST be held to half its timeout.
- **wait-timeout**: A wait that has not settled by its timeout MUST end with what it had (or "(no output)" when it had none) followed by the line "[still running — wait for more output, or interrupt it]". A wait's settle only starts once output has arrived, so a wait on a terminal that prints nothing runs to its timeout.
- **wait-empty**: A wait that ends by settling or being replaced with no output collected MUST return "(no output)".
- **wait-flush**: A wait that ends by its settle or its timeout MUST first report output the terminal printed but the chat has not yet reported, so none is lost inside the quiet period.
- **wait-activity**: Quiet MUST be measured from the terminal's own output activity, not from reports, so a stream reported once per maximum latency is not judged finished between two reports.
- **unclaimed-keep**: A reply reported while no caller waits MUST be kept, and only the latest 64 KiB of characters kept, dropping the oldest whole replies but never the only one.
- **unclaimed-dropped-marker**: A wait that replays unclaimed output after dropping some MUST begin with the line "[… earlier output dropped]".
- **unclaimed-cleared**: Starting any wait MUST discard the unclaimed output.
- **exit-handling**: When the terminal's state becomes terminated, the session MUST report what the shell printed last, emit "[the terminal's shell has exited]" as a reply, give a waiting caller that text and end its wait at once, disconnect, and then call `terminalDidExit`.
- **screen-lines**: `screen(lines:)` MUST return the last `lines` lines of the terminal's screen, with trailing blank lines removed, and at least one line when `lines` is below one.
- **screen-not-connected**: `screen(lines:)` MUST return nil when there is no terminal.
- **main-actor**: The session MUST be used only from the main actor.
- **alternate-screen**: Output drawn while a full-screen program has the alternate screen up MUST NOT be reported: the session reads the terminal's screen snapshot through the tracker, and the tracker returns nothing while the snapshot says the alternate screen is current. The session has no check of its own.
- **pre-connection-send**: A message sent while no terminal is connected MUST NOT be queued for a later connection; the failed turn described under `send-not-connected` is the only result.
## Appearance

Not applicable: the session is non-visual; its replies and failures are events that a transcript view draws.

## States

| State | Appearance change |
|-------|------------------|
| Disconnected (default) | No terminal; sends fail with a turn failure and calls return the not-connected text. |
| Connected, idle | Subscribed to the terminal's output activity and state; no wait and no timers. |
| Connected, collecting | Quiet and latency timers running after output arrived. |
| Waiting (armed) | A caller waits; its settle and timeout timers run. |
| Waiting (unarmed) | A run has typed its text but not yet its Return; nothing can settle it. |
| Exited | The shell has ended; the session reports it, ends the wait, disconnects and calls `terminalDidExit`. |
| Closed | The event stream is finished and released. |
| Pressed | Not applicable: the session has no interactive element. |
| Disabled | Not applicable: the composer is never locked, since the state is never responding. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long command is reported as still running at its timeout. |

## Accessibility

Not applicable: the session is not a user interface; it presents no view or control. The transcript view that shows its events carries the accessibility.

## Conformance Test Vectors

The vectors that name a test are from `TerminalChatSessionTests`, which drives a real `/bin/sh` through a connected terminal session. The rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-session-001 | run-reply, wait-timeout, output-report-latency (testOutputThatNeverPausesStillReachesTheRun) | Run `while true; do echo tick; sleep 0.1; done` with settle 1.5 s and timeout 3 s | The reply contains "tick" and ends with the still-running line. |
| terminal-chat-session-002 | wait-settle-cap (testASettleLongerThanTheTimeoutStillReportsAFinishedCommand) | Run `echo done` with settle 30 s and timeout 4 s | The reply contains "done" and not the still-running line. |
| terminal-chat-session-003 | interrupt-wait, wait-timeout (testInterruptWaitsAsLongAsItIsTold) | Interrupt a process that ignores Control-C with settle 0.5 s and timeout 2 s | The reply ends with the still-running line, after less than 5 s. |
| terminal-chat-session-004 | unclaimed-keep, wait-replay, run-fresh (testOutputAfterARunGaveUpGoesToWaitNotToTheNextRun) | Run `sleep 1; echo late-one` with timeout 0.6 s, wait 2 s, then wait for output; then the same with late-two followed by a run of `echo next` | The first wait returns "late-one"; the next run returns "next" and not "late-two". |
| terminal-chat-session-005 | exit-handling (testAShellThatExitsLetsGoAtOnce) | Run `exit` with timeout 30 s | The reply ends with the shell-exited text, in under 10 s; the chat's terminal is nil and the terminal is no longer running. |
| terminal-chat-session-006 | send-return-separate (testReturnArrivesAsAWriteOfItsOwn) | Run a program that reads two raw chunks, then send "hello" | The program sees `hello` then `\r` as two chunks. |
| terminal-chat-session-007 | run-armed-late (testAShortSettleStillGetsTheCommandsOutput) | Run `echo $((40+2))QQ` with settle 50 ms | The reply contains "42QQ" and the next wait does not. |
| terminal-chat-session-008 | send-order (testQuickSendsKeepTheirOrder) | Send "one" then "two" to a program reading raw input until two Returns | It reads `one\rtwo\r`. |
| terminal-chat-session-009 | send-closes-target, close (testAMessageSentJustBeforeClosingStillRuns) | Send `echo closed$((1+1))` then close at once | The terminal's screen shows `closed2`. |
| terminal-chat-session-010 | run-armed-late (testATimeoutShorterThanTheReturnDelayStillGetsTheOutput) | Run `echo $((6*7))ZZ` with timeout 400 ms | The reply contains "42ZZ" and not the still-running line. |
| terminal-chat-session-011 | run-not-connected, screen-not-connected, send-not-connected | A session with no terminal: run, wait, interrupt, screen, send | The not-connected text for the three waits; nil for screen; a turn failure "Not connected to a terminal." for send. |
| terminal-chat-session-012 | initial-state, unsent-events | Produce a reply (connect to a terminal showing a prompt) before subscribing, then subscribe | First event is ready, then the held started, delta and finished events. A message sent before subscribing is not among them. |
| terminal-chat-session-013 | screen-lines | A screen with 3 text rows then blank rows; `lines` 2, 0 | The last two text rows; with 0, the last one row. |
| terminal-chat-session-014 | wait-timeout, wait-empty | A wait on a terminal that prints nothing, with timeout 2 s | After 2 s, "(no output)" followed by the still-running line. |
| terminal-chat-session-015 | unclaimed-dropped-marker | More than 64 KiB of unclaimed replies then a wait | The reply starts with "[… earlier output dropped]". |
| terminal-chat-session-016 | connect-initial-output, connect-replace | Connect to a terminal showing a prompt | A started, delta and finished event with the prompt text, and no waiting caller receives it. |
| terminal-chat-session-017 | interrupt | Send a message, interrupt before its Return | Control-C is written and no Return follows. |

## Edge Cases

- **Null / empty input**: Empty text sends only a Return (MUST). Connecting to nil closes without dropping typed text (MUST). An empty wait returns "(no output)" (MUST).
- **Boundary values**: Settle is held to half of timeout (MUST); `lines` below 1 returns one line (MUST); unclaimed output above 64 KiB drops the oldest replies but keeps at least one (MUST).
- **Concurrent access**: Main-actor only. One wait at a time: a second ends the first with what it had (MUST). Two quick sends keep their order (MUST). An interrupt between a message's text and its Return drops the Return; an interrupt or a new connection drops messages not yet typed (MUST).
- **Error states**: A send with no terminal fails the turn, non-retryably (MUST). A shell that exits ends any wait with the exit text (MUST).
- **Offline / disconnected state**: Not applicable: the channel is a local terminal, not a network. The chat disconnected is the not-connected path.
- **Released session**: Queued input tasks hold the session weakly; one that outlives it still types its text and Return to the terminal it was sent to (MUST).
- **Echo of a private terminal**: The echoed line is taken as the terminal presents it, not as typed, because a private terminal may have changed it (MUST).
- **Interactive programs**: Tab completion, line editors and alternate-screen programs are not supported; see `alternate-screen`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `quietPeriod` | `Duration` | 300 ms | How long output must stop before it counts as one reply. |
| `maximumLatency` | `Duration` | 1 s | Longest output waits to be reported while it keeps coming. |
| `returnDelay` | `Duration` | 250 ms | Pause between typing the text and writing Return. |
| settle | `Duration` | 1.5 s | Quiet a wait needs, from the shared defaults. |
| timeout | `Duration` | 60 s (10 s for interrupt) | Longest a wait waits, from the shared defaults. |
| `lines` | `Int` | 40 | Lines `screen` returns. |
| `unclaimedLimit` | characters | 64 KiB | Cap on kept unclaimed output. |
| `terminalDidExit` | closure | nil | Called after the shell exits and the chat has let go. |

## Deep Linking

Not applicable: the session defines no URL scheme and has no screen to link to.

## Localization

Not applicable: the failure message, the not-connected text, the exit text, the still-running line, the dropped-output marker and "(no output)" are protocol text read by programs and a transcript, written in English in the source and not looked up in a localization table.

## Accessibility Options

Not applicable: the session presents no UI and responds to no accessibility display option.

## Feature Flags

Not applicable: the session contains no feature-flag reference.

## Analytics

Not applicable: the session contains no analytics call.

## Privacy

- **Data collected**: Everything typed into the terminal and everything it prints, passed through the chat as transcript events and returned strings.
- **Storage**: In memory only: the unsent events and up to 64 KiB of unclaimed output, until claimed or the chat is released; the transcript is the subscriber's.
- **Transmission**: None by this type; a persona's tool or the control server relays the strings it returns.
- **Retention**: Replies are retained as unclaimed output until a wait claims them, the chat is dropped, or the 64 KiB limit forces them out.
- **Concealment**: The session does no concealment of its own; a private terminal's screen, and its `presentable` text of the echo, are already concealed, and every reply is read off that screen.
- **Security**: Anyone with the session can type any command into the connected shell; the session performs no authorization.

## Logging

Not applicable: the session calls no logging API, so typed text and replies are never written to a log by it.

## Platform Notes

- **SwiftUI**: Source is `macOS/Features/TerminalSession/TerminalChatSession.swift`, with no view code; a SwiftUI chat view consumes `events()` through an `AsyncStream` task and calls `send`. It needs `TerminalSession`, `TerminalOutputTracker` and the `ChatSession` contract from the core framework.
- **Compose**: Hold the terminal as a weak reference, expose a `Flow<ChatEvent>` from a `MutableSharedFlow` with replay for held events, run the quiet, latency, settle and deadline timers as coroutine `delay` jobs on `Dispatchers.Main`, and answer a waiting caller through a `CompletableDeferred<String>`.
- **React/Web**: A browser cannot host a shell; a Node host would use `node-pty` with an `onData` listener, `setTimeout` for the timers, an async iterator for events and a `Promise` per wait, with the same one-wait-at-a-time rule.
- **AppKit / UIKit**: The source is `@MainActor` Swift using Combine for the terminal's output activity and state, and `Task.sleep` for the timers. iOS has no shell to connect to, so it does not apply there.
- **WinUI 3**: Use a ConPTY pseudo console (`CreatePseudoConsole`) as the terminal and keep the screen as a buffer the tracker can diff. Expose events as an `IAsyncEnumerable<ChatEvent>` from a `Channel<ChatEvent>`, with a list for held events. Marshal calls onto the UI thread with `DispatcherQueue` and run the quiet, latency, settle and deadline timers as `Task.Delay` with a `CancellationTokenSource` each. Write the text and then, after `returnDelay`, a separate `\r` write to the pipe handle; send Control-C as the byte 0x03. A wait is a `TaskCompletionSource<string>`; hold the terminal as a `WeakReference<TerminalSession>`, and cap the unclaimed list at 64 KiB with a `Queue<string>`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalChatSession.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Report output once it has been quiet for a period, and also at a maximum latency.
**Rationale**: The source says a shell prints in bursts and that without the pause one command's output would arrive as a dozen fragments, while a stream that never pauses, such as `yes` or `tail -f`, must still reach the transcript and whoever waits on it.
**Approved**: pending

**Decision**: Write Return as a separate write after a pause rather than inside the text.
**Rationale**: The source says a program reading keystrokes, Claude Code among them, takes a long line in one write for a paste and keeps the Return as pasted text, so the message sits unsent; a Return on its own after a pause reads as a key press.
**Approved**: pending

**Decision**: Measure quiet from the terminal's output activity, not from the replies.
**Rationale**: The source says a stream that never pauses is reported only once per maximum latency, so a settle shorter than that would judge it finished between two reports.
**Approved**: pending

**Decision**: Hold a wait's settle to half its timeout.
**Rationale**: The source says output that stops early is always judged finished before the deadline judges it still running; a settle as long as the timeout would lose every race.
**Approved**: pending

**Decision**: Keep unclaimed output, capped at the latest 64 KiB.
**Rationale**: The source says output a slow command prints after its wait gave up is not lost, but a chat left connected to a busy log would otherwise hold all of it.
**Approved**: pending

**Decision**: Do not start a run's settle or timeout until its Return is written.
**Rationale**: The source says the echo of the text alone would settle a short wait before the command starts, and its output would go to whichever wait came next; a command's time is counted from the Return.
**Approved**: pending

**Decision**: Let text already typed get its Return in its own terminal, and only Control-C drops it.
**Rationale**: The source says closing a pane must never leave a command typed but not run.
**Approved**: pending

**Decision**: Never report a responding state.
**Rationale**: The source says a shell has no turns, so the composer is never locked waiting for one to end.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | access-patterns |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

Separation of concerns passes: screen diffing is the tracker's, the protocol defaults are the control type's, and the session handles typing, timing and the event stream. Unit-test coverage is partial: ten tests drive a real shell through run, wait, interrupt, exit, return timing, ordering and close, but none covers the unclaimed-output cap, the dropped marker, `screen`, send with no terminal or the event stream's held events. Timeout handling passes because every wait ends at its timeout with a still-running marker rather than hanging, and an exit ends it at once. Timeout configuration passes because settle and timeout are parameters with named defaults and the settle is capped to half the timeout. No PII in logs passes because the session calls no logging API.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
