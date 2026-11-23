---
id: b71b349b-5c60-41f4-b664-49085ac5d988
title: "Terminal Chat Control"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The protocol an outside process such as Claude Code uses, through the app's MCP tools, to list Terminal Chats, type into one and read back the reply."
platforms:
  - swift
  - macos
tags:
  - unix-socket
  - terminal
  - protocol
  - wire
depends-on: []
related:
  - 80fecda2-6440-497a-ba28-c77eb05cc996
  - 00ef3e01-de2f-4f48-bd3c-86f15fb4f72b
references: []
approved-by: ""
approved-date: ""
---

# Terminal Chat Control

## Overview

`TerminalChatControl` is the contract between an app that hosts Terminal Chats and a process outside it, such as Claude Code in an ordinary terminal. The outside process can list the chats, type a command into one and get back what the terminal printed, concealed by that chat's substitutions exactly as its own transcript shows it, ask for more output from a command that outlasted the first wait, send Control-C, or read the last lines on the screen. The enum holds the actions, the request and reply shapes, the shared defaults and limits and the chat resolver, independent of any transport. The app serves it as MCP tools through `TerminalChatDirectoryToolSource` ([adhsdk.ingredient.workspace.terminal.terminal-chat-control-server](cookbook:80fecda2-6440-497a-ba28-c77eb05cc996)), and the chat that runs the command is `TerminalChatSession` ([adhsdk.ingredient.workspace.terminal.terminal-chat-session](cookbook:00ef3e01-de2f-4f48-bd3c-86f15fb4f72b)), both in the macOS target, outside these sources.

## Behavioral Requirements

- **action-values**: `Action` MUST be a String-backed `Codable` enum with five cases: `list`, `run`, `wait`, `interrupt` and `screen`.
- **action-list**: `list` MUST return the chats the app hosts.
- **action-run**: `run` MUST type `command` into the chat and return the reply.
- **action-wait**: `wait` MUST return more output from a command that outlasted `run`.
- **action-interrupt**: `interrupt` MUST send Control-C and return what the terminal printed in response.
- **action-screen**: `screen` MUST return the last `lines` lines on the terminal's screen.
- **request-fields**: A `Request` MUST carry `action` and the optional `chat`, `command`, `settle`, `timeout` and `lines`; it MUST be `Codable`, `Sendable` and `Equatable`.
- **request-init-defaults**: `Request.init` MUST require `action` and default every other field to nil.
- **request-chat-field**: `chat` MUST be a chat id or a prefix of one, and MAY be omitted when the app hosts exactly one chat.
- **request-timeout-meaning**: `timeout` MUST be the most seconds to wait; a command still printing then MUST be reported as still running, not failed: `Response` has no field for this, so the signal is a marker appended to `output`, a newline followed by `[still running — wait for more output, or interrupt it]`.
- **request-settle-meaning**: `settle` MUST be the seconds output has to stop for before a reply is complete.
- **chat-fields**: A `Chat` MUST carry `id`, `project`, `directory`, `paneNumber` (Int) and `connected` (Bool).
- **chat-pane-number**: `paneNumber` MUST be the pane's number in its project window, as the window shows it.
- **chat-connected**: `connected` MUST say whether the chat has a terminal to type into.
- **response-fields**: A `Response` MUST carry the optional `error`, `app`, `chats`, `chat` and `output`.
- **response-init-defaults**: `Response.init` MUST default every parameter to nil, so `Response(output: "ok")` sets `output` alone.
- **response-success**: `isSuccess` MUST be true exactly when `error` is nil.
- **response-failure**: `Response.failure(_:)` MUST build a response whose only field set is `error`.
- **response-app**: `app` MAY name the app answering, for a client talking to several; the tools (`TerminalChatDirectoryToolSource`) answer plain text and leave it unset.
- **response-chat**: `chat` MUST name the chat that answered a run, wait, interrupt or screen.
- **default-settle**: `Defaults.settle` MUST be 1.5 seconds.
- **default-timeout**: `Defaults.timeout` MUST be 60 seconds.
- **default-interrupt-timeout**: `Defaults.interruptTimeout` MUST be 10 seconds, because Control-C either works quickly or not at all.
- **default-lines**: `Defaults.lines` MUST be 40.
- **default-maximums**: `Defaults.maximumSettle` MUST be 60 seconds and `Defaults.maximumTimeout` MUST be 600 seconds.
- **default-timeout-for-action**: `Defaults.timeout(for:)` MUST return `interruptTimeout` for `interrupt` and `timeout` for every other action.
- **defaults-single-statement**: `Defaults` MUST be the one statement of these numbers, read by the chat session's own defaults, the app's tools and the tools' descriptions.
- **resolve-prefix**: `resolve(_:in:)` MUST pick the chat whose id starts with the query, compared ignoring case.
- **resolve-only-chat**: `resolve` MUST pick the only chat when the query is nil and exactly one chat exists.
- **resolve-none**: `resolve` MUST fail with `No Terminal Chat with id <query>.` when a query matches no chat, using the query lowercased, and with `There is no Terminal Chat open.` when the query is nil and there are no chats.
- **resolve-many**: `resolve` MUST fail with `More than one Terminal Chat matches — choose one of: <ids>` when more than one chat matches, with the ids joined by a comma and a space, and this applies to a nil query when several chats exist.
- **resolve-error-type**: The failure MUST be a `ResolveError` that carries a `message` and is `Equatable`.
- **host-answer-shape**: The host MUST answer `list` with the chats and every other success with the chat's output; the tools answer the chats as JSON and the output as plain text, and a failure as an error result carrying the message.
- **host-clamp**: The host MUST clamp `settle` and `timeout` to at least 0.1 seconds and at most `maximumSettle` and `maximumTimeout`.
- **host-run-needs-command**: The host MUST fail a `run` with a missing or empty `command` with `run needs a command.`.
- **host-not-connected**: The host MUST fail a request for a chat that has no terminal with the message `Terminal Chat <id> is not connected to a terminal — use Connect to Terminal in its pane's Settings.`, where `<id>` is the resolved chat's full id.
- **host-privacy**: The host MUST present a chat's project and directory through the connected terminal's concealment, and read output back only as that terminal shows it, so a private terminal's privacy words replace the real ones.
- **host-settle-cap**: The chat session MUST hold `settle` to at most half of `timeout` for a wait, so output that stops early is not judged unfinished against the deadline.
- **host-list-order**: The host MUST list chats sorted by project and then `paneNumber`.
- **host-screen-trim**: `screen` MUST drop trailing blank lines before taking the last `lines` lines.
- **transport-independent**: `TerminalChatControl` MUST define no transport: no socket, no client call and no host discovery; a host serves the protocol through its own transport, the app's MCP tools.
## Appearance

Not applicable — this is a wire protocol and helper functions, not a visual component.

## States

Not applicable — this is a wire protocol and helper functions, not a visual component.

## Accessibility

Not applicable — this is a wire protocol and helper functions, not a visual component.

## Conformance Test Vectors

`TerminalChatControlConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Terminal/`) covers every vector below; `TerminalChatSessionTests` covers the session behind it. The vectors are written against `resolve`, `Defaults` and the codable shapes, which need no running app. The numbers 013 to 020, 022 and 023 belonged to the socket helpers and the client call, which are gone, and are not reused.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-control-001 | resolve-only-chat | `resolve(nil, in: [one chat])` | success with that chat |
| terminal-chat-control-002 | resolve-none | `resolve(nil, in: [])` | failure `There is no Terminal Chat open.` |
| terminal-chat-control-003 | resolve-prefix | chats `a1b2c3d4` and `f9e8d7c6`; `resolve("A1B", in: both)` | success with `a1b2c3d4`, the prefix compared ignoring case |
| terminal-chat-control-004 | resolve-none | `resolve("zz", in: both)` | failure `No Terminal Chat with id zz.` |
| terminal-chat-control-005 | resolve-many | chats `a1b2c3d4` and `a1ffffff`; `resolve("a1", in: both)` | failure `More than one Terminal Chat matches — choose one of: a1b2c3d4, a1ffffff` |
| terminal-chat-control-006 | resolve-many | `resolve(nil, in: both)` | the same many-match failure, listing both ids |
| terminal-chat-control-007 | default-timeout-for-action | `Defaults.timeout(for: .interrupt)`, then for `.run`, `.wait`, `.screen` and `.list` | 10, then 60 for each of the others |
| terminal-chat-control-008 | default-settle, default-lines, default-maximums | the `Defaults` constants | 1.5, 40, 60 and 600 |
| terminal-chat-control-009 | request-init-defaults, request-fields | `Request(action: .list)` encoded and decoded | an equal request, with every optional field nil |
| terminal-chat-control-010 | action-values | `Action.interrupt.rawValue`, and decoding `"screen"` | `interrupt`, and `.screen` |
| terminal-chat-control-011 | response-failure, response-success | `Response.failure("x")` | `error` is `x`, `isSuccess` false, every other field nil |
| terminal-chat-control-012 | response-success | `Response(output: "ok")` | `isSuccess` true |
| terminal-chat-control-021 | resolve-error-type | `resolve("zz", in: [])` | a failure whose `ResolveError.message` is `No Terminal Chat with id zz.`, equal to another `ResolveError` with the same message |
| terminal-chat-control-024 | request-chat-field | `resolve("", in: [two chats])` | the many-match failure, because an empty string is a prefix of every id |
| terminal-chat-control-025 | response-init-defaults | `Response(output: "ok")` | every field but `output` is nil |
## Edge Cases

- **Empty or missing input**: a nil `chat` resolves only when exactly one chat exists; an empty-string `chat` matches every id as a prefix, so it behaves like nil and fails when several chats exist.
- **Ambiguous prefix**: a prefix that matches several chats MUST fail and list the matching ids rather than pick one.
- **Case**: chat ids compare ignoring case and the query is lowercased in the not-found message.
- **No chats**: `list` returns an empty `chats` array, and every other action fails with `There is no Terminal Chat open.` when no query is given.
- **Chat without a terminal**: a chat that exists but is not connected is listed with `connected` false and refuses `run`, `wait`, `interrupt` and `screen`.
- **Missing command**: `run` with a nil or empty `command` fails with `run needs a command.`.
- **Out-of-range timing**: a `settle` or `timeout` of zero or a negative number clamps to 0.1 seconds and a value above the maximum clamps down to it; the request is never rejected for this.
- **Screen line count**: a `lines` below 1 is raised to 1 by the chat session's `screen`.
- **Command that outlasts the wait**: `run` returns what it has when the timeout passes and reports the command as still running; the client MUST use `wait` for more.
- **Malformed arguments**: the tools answer an error naming the tool when the arguments do not decode.
- **Concurrent access**: calls are served one at a time on the main actor; the chat session ends a previous wait with what it had when a new one starts, so two clients driving the same chat can cut each other's wait short.
- **App not running**: the tools are served by the running app's MCP host, so with the app not running there is nothing to call; the host's own error reaches the client.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| settle | Double | 1.5 (cap 60) | Seconds output has to stop for before a reply is complete. |
| timeout | Double | 60, or 10 for interrupt (cap 600) | The most seconds a run, wait or interrupt waits. |
| lines | Int | 40 | Lines `screen` returns. |

## Deep Linking

Not applicable: this protocol defines no URL or deep link; it is reached through the app's MCP tools.
## Localization

The failure messages (`No Terminal Chat with id`, `There is no Terminal Chat open.`, `run needs a command.` and the not-connected text) are English strings for a command-line client and a coding agent, not interface text; they are hardcoded in the source with no string table.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: none by this code; a request carries a command the caller chose and a reply carries terminal output.
- **Storage**: none; nothing is written to disk by this code.
- **Transmission**: none by this code; the app's MCP host carries requests and replies, behind its own bearer token on a loopback port.
- **Retention**: none defined by this code; the chat's transcript, outside these sources, records what was typed and printed.
- **Concealment**: output and the listed project and directory pass through the connected terminal's concealment, so a private terminal's privacy words replace its real ones.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used here; the app's Terminal Chat panes are served by the tools and need no change to be driven.
- **Compose**: a Kotlin port keeps the same field names as `kotlinx.serialization` data classes; the five actions and the resolver are plain logic.
- **React/Web**: a TypeScript port keeps the same field names as interfaces and the resolver as a pure function; the transport is the host's MCP server.
- **AppKit / UIKit**: The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalChatControl.swift`: a caseless `public enum` with nested `Codable` types, the `Defaults` constants and `resolve`.
- **WinUI 3**: Use C# `record` types with `System.Text.Json` and the same property names, and the resolver as a static method; the transport is the host's MCP server.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalChatControl.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The protocol defines no transport.
**Rationale**: Apps suite Phase 4 retires the per-app Unix socket, its directory helpers and the `adterm` client; the app serves the protocol as MCP tools through the host it already registers with, so the vocabulary stays and the door is the host's.
**Approved**: pending

**Decision**: `Defaults` is the single statement of the timing numbers.
**Rationale**: Three readers need these numbers: the session's own defaults, the app's tools and the tools' descriptions; one place stops them drifting.
**Approved**: pending

**Decision**: A command still printing at the timeout is reported as still running, with `wait` to collect more.
**Rationale**: The `timeout` and `wait` actions separate "the command failed" from "the command is not done", so a long build does not look like an error.
**Approved**: pending

**Decision**: `interrupt` gets a shorter default timeout than `run`.
**Rationale**: Control-C either works quickly or not at all, so waiting the full `run` timeout for it only delays a failure report.
**Approved**: pending

**Decision**: Everything goes through the chat, never directly through the terminal.
**Rationale**: Going through the chat means the action shows in the chat's transcript as it happens, and a private terminal reads back only what it shows, its privacy words in place of the real ones.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

separation-of-concerns passes: the enum holds the wire shapes, shared numbers and the resolver; answering requests lives in `TerminalChatDirectoryToolSource` and running commands in `TerminalChatSession`. unit-test-coverage passes: every vector (001 to 012, 021, 024 and 025) is covered by `TerminalChatControlConformanceTests.swift` (`Tests/AgenticDeveloperHubSDKCoreTests/Terminal/`). data-minimization passes: the protocol carries only the fields each action needs, and the listing conceals the project and directory as the terminal does.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-23 | Mike Fullerton | Apps suite Phase 4: the socket half (directory helpers, Host, runningHosts, send, wire framing) is removed; the protocol defines no transport. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (TerminalChatControlConformanceTests.swift, 24 of 25 vectors; 019 skipped, needs 40 real seconds); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Pinned the newline-delimited wire framing, the still-running marker, host fields, Response init defaults and exact error strings; added five vectors, related links, a tag swap and corrected Windows and Android notes. |
