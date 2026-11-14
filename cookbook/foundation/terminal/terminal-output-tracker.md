---
id: 6e81fe86-b97d-4af9-a45b-0ace8784fbed
title: "Terminal Output Tracker"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Turns successive snapshots of a rendered terminal screen into the new text printed since the last read, leaving out the prompt already shown and the command's echo."
platforms:
  - swift
  - macos
tags:
  - foundation
  - terminal
  - logic
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Output Tracker

## Overview

`TerminalOutputTracker` turns successive snapshots of a terminal into the text the terminal has printed since the last read, which is what a chat transcript shows as the terminal's reply. A `TerminalScreenSnapshot` is the terminal's rendered text at one moment: every line still held, the row number of the first of them, the cursor's row, and whether a full-screen program has the alternate screen up. Rows are numbered scroll-invariantly, counted from the first line the terminal ever had, so a row number names the same line before and after output scrolls the oldest lines away. The tracker reads the rendered screen, not the byte stream, because the terminal has already applied every cursor move, carriage return and colour code. Everything from the last row read up to the cursor's row is new. The cursor's own row is usually an unfinished prompt, so it is shown and remembered, and only what is added to it later is shown again. The tracker is a value type with no I/O; the chat session in the macOS target owns one, feeds it snapshots and tells it what it sent.

## Behavioral Requirements

- **snapshot-fields**: A `TerminalScreenSnapshot` MUST carry `lines` (array of String, oldest first), `firstRow` (Int, the row number of `lines[0]`), `cursorRow` (Int) and `isAlternateScreen` (Bool), and MUST be `Sendable` and `Equatable`.
- **snapshot-row-numbering**: A row number MUST count from the first line the terminal ever had, trimmed or not, so it names the same line before and after the oldest lines scroll away; `firstRow` is how many lines have been trimmed off the top.
- **tracker-type**: `TerminalOutputTracker` MUST be a `public struct` that is `Sendable`, with mutating `noteSent(_:)` and `newOutput(in:)`.
- **init-empty**: `init()` MUST start with no position, so the first `newOutput` call reads from the cursor's row of the snapshot it is given.
- **init-from-top**: `init(fromTopOf:)` MUST start at the snapshot's `firstRow`, so the first read returns everything the snapshot still holds, startup text included.
- **init-starting-at**: `init(startingAt:)` MUST start at the snapshot's cursor row and remember that row's text as already shown, so history from before the chat connected is not replayed as a reply.
- **init-starting-at-range**: `init(startingAt:)` MUST remember no shown text when the cursor row is not among the snapshot's lines.
- **new-output-nil-alternate**: `newOutput(in:)` MUST return nil, and change nothing, when the snapshot is on the alternate screen, because its rows are a canvas that vanishes when the program exits and not a record of output.
- **new-output-nil-empty**: `newOutput(in:)` MUST return nil, and change nothing, when the snapshot has no lines.
- **cursor-clamped**: `newOutput` MUST clamp the cursor row into the range of rows the snapshot holds.
- **read-range**: `newOutput` MUST read every row from the last row read up to and including the cursor's row.
- **cursor-row-shown**: `newOutput` MUST include the cursor's own row, an unfinished prompt included, and remember it as shown.
- **shown-prefix-stripped**: When the first row to read starts with the text already shown for it, `newOutput` MUST drop that text from the row, so a prompt shown at the end of one reply does not appear again at the start of the next.
- **resume-lost-trimmed**: When the row to resume from has been trimmed off the top of the snapshot, `newOutput` MUST start again at the cursor's row and forget the shown text.
- **resume-lost-cursor-back**: When the cursor is above the row to resume from, as after a clear or a reset, `newOutput` MUST start again at the cursor's row and forget the shown text.
- **echo-record**: `noteSent(_:)` MUST record the text sent with leading and trailing whitespace and newlines removed, and when what remains is empty MUST record nothing and clear any echo already pending.
- **echo-latest-wins**: A new `noteSent` MUST replace an echo not yet seen.
- **echo-removal**: When an echo is pending and the first row read (after any shown prefix is removed) is not blank, `newOutput` MUST drop that row when its text with surrounding spaces removed ends with the echo, compared ignoring case.
- **echo-first-row-only**: Only the first row read MAY be treated as the echo, and only when it is not blank; a blank first row is never skipped to reach a later row, and everything after the first row is the command's output.
- **echo-cleared**: The pending echo MUST be cleared once a non-blank first row has been tested, whether or not it matched, and MUST stay pending across a read whose first row is blank or that returns nil early (alternate screen or no lines).
- **output-trim**: The returned text MUST have trailing whitespace removed from each row and blank rows removed from the start and end, and MUST keep blank rows between non-blank rows.
- **output-join**: Rows MUST be joined with a newline.
- **output-nil-when-blank**: `newOutput` MUST return nil when no non-blank text is left.
- **state-advance**: After a read, `newOutput` MUST set the next row to read to the cursor's row and the shown text to that row's full text.

## Appearance

Not applicable — this is a pure text-diffing component, not a visual component.

## States

Not applicable — this is a pure text-diffing component, not a visual component.

## Accessibility

Not applicable — this is a pure text-diffing component, not a visual component.

## Conformance Test Vectors

Vectors 001 to 006 are the six tests in `TerminalOutputTrackerTests`; the rest follow from the source's logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-output-tracker-001 | init-starting-at, shown-prefix-stripped | start at `["old", "%"]` cursor 1; read the same snapshot (`startsAtTheCursor`) | nil |
| terminal-output-tracker-002 | echo-removal, output-trim | start at `["%"]` cursor 0; `noteSent("echo hi")`; read `["% echo hi", "hi", "%"]` cursor 2 (`dropsTheEcho`) | `hi` then newline then `%` |
| terminal-output-tracker-003 | shown-prefix-stripped, state-advance | start at `["%"]` cursor 0; read `["%", "a", "%"]` cursor 2; `noteSent("ls")`; read `["%", "a", "% ls", "file", "%"]` cursor 4 (`stripsTheShownPrompt`) | `file` then newline then `%`, the prompt not repeated |
| terminal-output-tracker-004 | snapshot-row-numbering, read-range | start at `["x", "%"]` cursor 1; read `["%", "out", "%"]` cursor 3 with first row 1 (`survivesTrimming`) | `out` then newline then `%` |
| terminal-output-tracker-005 | new-output-nil-alternate | read `["vim stuff"]` on the alternate screen (`ignoresAlternateScreen`) | nil |
| terminal-output-tracker-006 | resume-lost-cursor-back | start at `["a", "b", "c", "%"]` cursor 3; read `["%", "", "", ""]` cursor 0 (`recoversFromAClear`) | `%` |
| terminal-output-tracker-007 | init-from-top | `init(fromTopOf:)` a snapshot `["boot", "%"]` first row 0 cursor 1; read it | `boot` then newline then `%` |
| terminal-output-tracker-008 | new-output-nil-empty | read a snapshot with no lines | nil |
| terminal-output-tracker-009 | resume-lost-trimmed | start at row 1; read a snapshot whose first row is 5 with lines `["p", "q"]` and cursor 6 | `q` only, the read restarting at the cursor row because row 1 is gone |
| terminal-output-tracker-010 | cursor-clamped | read a snapshot of 2 lines starting at row 0 with cursor row 9 | the last line only, with no crash |
| terminal-output-tracker-011 | echo-record | `noteSent("  \n")`, then read a first row of `% x` | the row is kept, because nothing was recorded |
| terminal-output-tracker-012 | echo-removal | `noteSent("LS")`; first row `% ls` | the row is dropped, the match ignoring case |
| terminal-output-tracker-013 | echo-cleared | `noteSent("ls")`; first row `% pwd`; then a later read whose first row is `% ls` | both reads keep their rows, the echo cleared after the first non-blank row |
| terminal-output-tracker-014 | echo-latest-wins | `noteSent("a")` then `noteSent("b")`; first row `% b` | the row is dropped |
| terminal-output-tracker-015 | output-trim, output-nil-when-blank | rows `["", "  ", ""]` | nil |
| terminal-output-tracker-016 | output-trim | rows `["x   ", "", "y  "]` | `x`, a blank line, `y`, with trailing spaces removed |
| terminal-output-tracker-017 | echo-cleared | `noteSent("ls")`; first read has a blank first row and a later row; then the echo row arrives | the echo is still pending after the blank first row |
| terminal-output-tracker-018 | new-output-nil-alternate, state-advance | alternate-screen read, then a normal read of the same text | the alternate read changes nothing; the normal read returns the text |

## Edge Cases

- **Empty or missing input**: a snapshot with no lines returns nil and leaves the tracker as it was.
- **Alternate screen**: a read while a full-screen program (vim, less) is up returns nil and leaves the tracker as it was, so the reply picks up from where it stopped after the program exits.
- **Cursor outside the lines**: the cursor row is clamped into the snapshot's rows, so a snapshot whose cursor lies beyond the last line reads to the last line.
- **Output scrolled away**: when the row to resume from has been trimmed off the top, the tracker restarts at the cursor's row, so the lines that scrolled away unread are lost; the source accepts this over replaying stale text.
- **Clear or reset**: a cursor above the resume row restarts at the cursor's row with the shown text forgotten.
- **Prompt that changed**: when the first row does not start with the shown text, the row is returned whole.
- **Echo that does not match**: the first non-blank row is kept and the pending echo is dropped.
- **Wrapped echo**: a command long enough to wrap across rows is a row-based match against only the first row; a first row that does not end with the echo is kept as output. A caller that sends long commands sees the wrapped echo in the reply.
- **Blank first row**: a read whose first row is blank leaves the echo pending for the next read.
- **Echo as substring**: the echo test is a suffix match ignoring case, so output that happens to end with the command's text on the first row is dropped with it.
- **Empty send**: `noteSent` with text that is only whitespace records nothing, and a previously pending echo is cleared by it.
- **Concurrent access**: the type is a value with mutating methods; one owner reads and writes it, and a copy carries its own position.
- **Error and offline states**: the tracker does no I/O and has no error path; a terminal that has exited simply stops producing new rows.

## Configuration

Not applicable: the tracker has no configurable option.

## Deep Linking

Not applicable: this component defines no URL or deep link.

## Localization

Not applicable: the tracker holds no interface text; it passes through the terminal's own text unchanged except for trimming.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: none by this code; it returns text a terminal printed, which may hold anything the user's commands print.
- **Storage**: none; the tracker keeps the next row number, the last row's text and the pending echo in memory only.
- **Transmission**: none.
- **Retention**: none defined by this code; the chat transcript outside these sources records what the tracker returns.

## Logging

Not applicable: this code makes no log calls, so command output never reaches a log from here.

## Platform Notes

- **SwiftUI**: Not used here; the chat view shows what the session builds from `newOutput`.
- **Compose**: a Kotlin `class` with a `var nextRow: Int?`, `shownPrefix` and `pendingEcho`, `String.trimEnd()` for each row, and `lines` as a `List<String>`.
- **React/Web**: a TypeScript class with the same three fields; a terminal emulator such as xterm.js supplies the rendered rows through its buffer API.
- **AppKit / UIKit**: The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalOutputTracker.swift`: two `public struct` types, `trimmingCharacters(in:)` for the echo, and range-mapped row access; the macOS target builds the snapshot from its terminal view.
- **WinUI 3**: Use a C# `struct` or `record struct` with `string.TrimEnd()` per row and `StartsWith` and `EndsWith` with `StringComparison.OrdinalIgnoreCase`; build the snapshot from a ConPTY screen buffer, counting rows from the first line ever scrolled so row numbers stay stable.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalOutputTracker.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The tracker reads the rendered screen and not the byte stream.
**Rationale**: The source says this is what makes the problem tractable: the terminal has already applied every cursor move, carriage return and colour code, so a row is the text a person would read.
**Approved**: pending

**Decision**: Rows are numbered from the first line the terminal ever had.
**Rationale**: The source calls this scroll-invariant: a row number names the same line before and after output scrolls the oldest lines away, so the tracker can keep its place across trimming.
**Approved**: pending

**Decision**: The cursor's row is shown and remembered, and only what is added to it later is shown again.
**Rationale**: The source says the cursor row is usually an unfinished prompt, and this keeps a prompt from appearing at the end of one reply and again at the start of the next.
**Approved**: pending

**Decision**: The tracker starts at the cursor's row for a chat that connects to a running terminal, and from the top for one that wants startup text.
**Rationale**: The source gives each initializer a purpose: `init(startingAt:)` keeps history from before the chat connected from being replayed as a reply, and `init(fromTopOf:)` shows what the terminal printed before anyone was listening.
**Approved**: pending

**Decision**: The command's echo is removed by matching the end of the first non-blank row, ignoring case.
**Rationale**: The source says the shell's echo is the command reappearing on the prompt row, so only the first non-blank row can be it; a suffix match survives whatever prompt text sits before it.
**Approved**: pending

**Decision**: Lost position restarts at the cursor's row and does not replay.
**Rationale**: The source says a trimmed row or a cursor sent back above the resume row leaves nothing to resume from, so reading starts again at what is on hand, trading some lost lines for no stale text.
**Approved**: pending

**Decision**: Alternate-screen snapshots report nothing.
**Rationale**: The source says a full-screen program's rows are a canvas, not a record of output, and they vanish when it exits.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

separation-of-concerns passes: the file holds a snapshot value and a pure position-tracking function; the terminal, its snapshots and the chat transcript live in `TerminalSession` and `TerminalChatSession` in the macOS target. unit-test-coverage is partial: six tests cover the cursor start, the echo, the shown prompt, trimming, the alternate screen and a clear, but none covers `init(fromTopOf:)`, an echo that does not match, a blank first row, a trimmed resume row, a cursor beyond the last line or the whitespace-only send, so vectors 007 to 018 rest on the source alone.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
