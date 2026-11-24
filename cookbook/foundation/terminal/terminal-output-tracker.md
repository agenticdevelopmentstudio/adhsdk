---
id: 6e81fe86-b97d-4af9-a45b-0ace8784fbed
title: "Terminal Output Tracker"
type: ingredient
version: 1.0.2
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
- **cursor-clamped**: `newOutput` MUST clamp the cursor row into the range of rows the snapshot holds, and MUST use the clamped row, not the raw `cursorRow`, for the read range and for **state-advance**.
- **read-range**: `newOutput` MUST read every row from the last row read up to and including the cursor's row.
- **cursor-row-shown**: `newOutput` MUST include the cursor's own row, an unfinished prompt included, and remember it as shown.
- **shown-prefix-stripped**: When the first row to read starts with the text already shown for it, `newOutput` MUST drop that text from the row, so a prompt shown at the end of one reply does not appear again at the start of the next.
- **resume-lost-trimmed**: When the row to resume from has been trimmed off the top of the snapshot, `newOutput` MUST start again at the cursor's row and forget the shown text.
- **resume-lost-cursor-back**: When the cursor is above the row to resume from, as after a clear or a reset, `newOutput` MUST start again at the cursor's row and forget the shown text.
- **echo-record**: `noteSent(_:)` MUST record the text sent with leading and trailing Unicode whitespace and newline characters removed (Swift's `.whitespacesAndNewlines` set), and when what remains is empty MUST record nothing and clear any echo already pending.
- **echo-latest-wins**: A new `noteSent` MUST replace an echo not yet seen.
- **echo-removal**: When an echo is pending and the first row read (after any shown prefix is removed) is not blank, `newOutput` MUST drop that row when its text, with leading and trailing space and tab characters (Swift's `.whitespaces` set, which excludes newlines) removed, ends with the echo, compared ignoring case. The same `.whitespaces` trim decides whether the first row is blank.
- **echo-first-row-only**: `newOutput` MUST NOT treat any row other than the first row read as the echo, and MUST NOT skip a blank first row to reach a later one; everything after the first row is the command's output.
- **echo-cleared**: The pending echo MUST be cleared once a non-blank first row has been tested, whether or not it matched, and MUST stay pending across a read whose first row is blank or that returns nil early (alternate screen or no lines).
- **output-trim**: The returned text MUST have trailing characters for which `Character.isWhitespace` is true (spaces, tabs and any other Unicode whitespace) removed from each row and blank rows removed from the start and end, and MUST keep blank rows between non-blank rows.
- **output-join**: Rows MUST be joined with a newline.
- **output-nil-when-blank**: `newOutput` MUST return nil when no non-blank text is left.
- **state-advance**: After every read that does not return early (alternate screen or no lines), including one that returns nil because no non-blank text is left, `newOutput` MUST set the next row to read to the (clamped) cursor's row and the shown text to that row's full text.

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
| terminal-output-tracker-009 | resume-lost-trimmed | `init(fromTopOf:)` a snapshot with lines `["a", "b"]`, first row 1, cursor row 2, so the next row is 1; then read a snapshot with lines `["p", "q"]`, first row 5, cursor row 6 | `q`, the read restarting at the cursor row because row 1 is gone |
| terminal-output-tracker-010 | cursor-clamped | `init()`; read a snapshot with lines `["x", "y"]`, first row 0, cursor row 9 | `y`, the cursor clamped to row 1, with no crash |
| terminal-output-tracker-011 | echo-record | `init()`; `noteSent("  \n")`; read lines `["% x"]`, first row 0, cursor row 0 | `% x`, because nothing was recorded |
| terminal-output-tracker-012 | echo-removal | `init()`; `noteSent("LS")`; read lines `["% ls"]`, first row 0, cursor row 0 | nil, the first row dropped as the echo, the match ignoring case |
| terminal-output-tracker-013 | echo-cleared | `init()`; `noteSent("ls")`; read lines `["% pwd"]`, first row 0, cursor row 0; then read lines `["% pwd", "% ls"]`, first row 0, cursor row 1 | `% pwd`, then `% ls`: the first read keeps its row and clears the echo, so the second read's `% ls` is not dropped |
| terminal-output-tracker-014 | echo-latest-wins | `init()`; `noteSent("a")` then `noteSent("b")`; read lines `["% b"]`, first row 0, cursor row 0 | nil, the row dropped |
| terminal-output-tracker-015 | output-trim, output-nil-when-blank | `init()`; read lines `["", "  ", ""]`, first row 0, cursor row 2 | nil |
| terminal-output-tracker-016 | output-trim, output-join | `init(fromTopOf:)` lines `["x   ", "", "y  "]`, first row 0, cursor row 2; read the same snapshot | `x`, a newline, an empty line, a newline, `y`: `"x\n\ny"`, with trailing spaces removed |
| terminal-output-tracker-017 | echo-cleared | `init(fromTopOf:)` lines `["", ""]`, first row 0, cursor row 1; `noteSent("ls")`; read the same snapshot; then read lines `["", "% ls", "done", "%"]`, first row 0, cursor row 3 | nil, then `done` newline `%`: the blank first row left the echo pending, so the second read dropped `% ls` |
| terminal-output-tracker-018 | new-output-nil-alternate, state-advance | `init(startingAt:)` lines `["old", "%"]`, first row 0, cursor row 1; read lines `["zz"]`, first row 0, cursor row 0 on the alternate screen; then read lines `["old", "%", "out", "%"]`, first row 0, cursor row 3 | nil, then `out` newline `%`: the alternate read changed nothing, so the second read resumed at row 1 with `%` shown |
| terminal-output-tracker-019 | state-advance | `init(fromTopOf:)` lines `["% ls"]`, first row 0, cursor row 0; `noteSent("ls")`; read the same snapshot; then read lines `["% ls", "out", "%"]`, first row 0, cursor row 2 | nil, then `out` newline `%`: the first read returned nil because only the echo was left, yet it advanced the next row and the shown text |
| terminal-output-tracker-020 | cursor-clamped, state-advance | `init(fromTopOf:)` lines `["a", "b"]`, first row 0, cursor row 9; read the same snapshot; then read lines `["a", "b", "c", "d"]`, first row 0, cursor row 3 | `a` newline `b`, then `c` newline `d`: the clamped row 1, not 9, is the next row to read |
## Edge Cases

- **Empty or missing input**: a snapshot with no lines returns nil and leaves the tracker as it was.
- **Alternate screen**: a read while a full-screen program (vim, less) is up returns nil and leaves the tracker as it was, so the reply picks up from where it stopped after the program exits.
- **Cursor outside the lines**: the cursor row is clamped into the snapshot's rows, so a snapshot whose cursor lies beyond the last line reads to the last line.
- **Output scrolled away**: when the row to resume from has been trimmed off the top, the tracker restarts at the cursor's row, so the lines that scrolled away unread are lost; the tracker accepts this over replaying stale text.
- **Clear or reset**: a cursor above the resume row restarts at the cursor's row with the shown text forgotten.
- **Prompt that changed**: when the first row does not start with the shown text, the row is returned whole.
- **Echo that does not match**: the first non-blank row is kept and the pending echo is dropped.
- **Wrapped echo**: a command long enough to wrap across rows is a row-based match against only the first row; a first row that does not end with the echo is kept as output. A caller that sends long commands sees the wrapped echo in the reply (a recorded Design Decision).
- **Blank first row**: a read whose first row is blank leaves the echo pending for the next read.
- **Echo as substring**: the echo test is a suffix match ignoring case, so output that happens to end with the command's text on the first row is dropped with it (a recorded Design Decision); for example, after `noteSent("ls")` a first row of `pls` is dropped.
- **Empty send**: `noteSent` with text that is only whitespace records nothing, and a previously pending echo is cleared by it.
- **Nothing non-blank left**: a read whose rows are all blank, or whose only non-blank row was the echo, returns nil but still advances the next row and the shown text.
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
- **Compose**: an immutable Kotlin `data class` with `nextRow: Int?`, `shownPrefix` and `pendingEcho`, whose `noteSent` and `newOutput` return the new state with `copy()` (a copy must carry its own position, as the Swift value type does), `String.trimEnd()` for each row, and `lines` as a `List<String>`.
- **React/Web**: an immutable TypeScript object with the same three fields, replaced on each call (or copied on write), since a shared mutable instance would alias the position that the Swift value type copies; a terminal emulator such as xterm.js supplies the rendered rows through its buffer API.
- **AppKit / UIKit**: This source is platform-neutral Foundation-only Swift with no AppKit or UIKit dependency; it runs unchanged on any Swift platform. The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalOutputTracker.swift`: two `public struct` types, `trimmingCharacters(in:)` for the echo, and range-mapped row access; the macOS target builds the snapshot from its terminal view.
- **WinUI 3**: Use a C# `struct` or `record struct` with `string.TrimEnd()` per row and `StartsWith` and `EndsWith` with `StringComparison.OrdinalIgnoreCase`; build the snapshot from a ConPTY screen buffer, counting rows from the first line ever scrolled so row numbers stay stable.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalOutputTracker.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The tracker reads the rendered screen and not the byte stream.
**Rationale**: This is what makes the problem tractable (the type's doc comment says so): the terminal has already applied every cursor move, carriage return and colour code, so a row is the text a person would read.
**Approved**: pending

**Decision**: Rows are numbered from the first line the terminal ever had.
**Rationale**: A row number is scroll-invariant (the `TerminalScreenSnapshot` doc comment): it names the same line before and after output scrolls the oldest lines away, so the tracker can keep its place across trimming.
**Approved**: pending

**Decision**: The cursor's row is shown and remembered, and only what is added to it later is shown again.
**Rationale**: The cursor row is usually an unfinished prompt, and remembering what was shown keeps a prompt from appearing at the end of one reply and again at the start of the next.
**Approved**: pending

**Decision**: The tracker starts at the cursor's row for a chat that connects to a running terminal, and from the top for one that wants startup text.
**Rationale**: Each initializer has its own purpose: `init(startingAt:)` keeps history from before the chat connected from being replayed as a reply, and `init(fromTopOf:)` shows what the terminal printed before anyone was listening.
**Approved**: pending

**Decision**: The command's echo is removed by matching the end of the first non-blank row, ignoring case.
**Rationale**: The shell's echo is the command reappearing on the prompt row (the doc comment on `noteSent`), so only the first non-blank row can be it; a suffix match survives whatever prompt text sits before it.
**Approved**: pending

**Decision**: Lost position restarts at the cursor's row and does not replay.
**Rationale**: A trimmed row or a cursor sent back above the resume row leaves nothing to resume from, so reading starts again at what is on hand, trading some lost lines for no stale text.
**Approved**: pending

**Decision**: Alternate-screen snapshots report nothing.
**Rationale**: A full-screen program's rows are a canvas, not a record of output, and they vanish when it exits (the doc comment on `isAlternateScreen`).
**Approved**: pending

**Decision**: A command long enough to wrap leaves its wrapped echo in the reply, as a known limitation.
**Rationale**: The echo test looks only at the first row, because a row-based match cannot tell a wrapped continuation from output. Revisit if callers send commands longer than the terminal's width and the doubled text proves noisy, for example by matching the echo across the first several rows.
**Approved**: pending

**Decision**: The echo test is a case-insensitive suffix match, so first-row output that happens to end with the command's text is dropped with it, as a known limitation.
**Rationale**: A suffix match survives whatever prompt text sits before the command, which an exact match would not. For example, after `noteSent("ls")` a first row of `pls` is dropped. Revisit if prompts become predictable enough to match the prompt and the command together.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |

separation-of-concerns passes: the file holds a snapshot value and a pure position-tracking function; the terminal, its snapshots and the chat transcript live in `TerminalSession` and `TerminalChatSession` in the macOS target. unit-test-coverage passes: `TerminalOutputTrackerTests` (`Tests/AgenticDeveloperHubSDKCoreTests/TerminalOutputTrackerTests.swift`) has a test for each of the twenty vectors.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (TerminalOutputTrackerTests.swift, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Wrote vectors 009 to 018 with concrete snapshots, added vectors 019 and 020, named the whitespace sets, stated that state advances on every non-early read with the clamped row, recorded two limitations as decisions and made the Compose and Web notes value-semantic. |
