---
id: 80fecda2-6440-497a-ba28-c77eb05cc996
title: "Terminal Chat Directory Tools"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The app's open Terminal Chats as a directory and five MCP tools (list, run, wait, interrupt, screen) that let Claude Code in another terminal type into a chat and read its concealed reply."
platforms:
  - swift
  - macos
tags:
  - terminal
  - terminal-chat
  - privacy
depends-on:
  - b71b349b-5c60-41f4-b664-49085ac5d988
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Chat Directory Tools
## Overview

This source holds the types that let a process outside the app drive the app's Terminal Chats, over the request, chat and default limits [adhsdk.ingredient.foundation.terminal.terminal-chat-control](cookbook:b71b349b-5c60-41f4-b664-49085ac5d988) defines. The client is Claude Code in another terminal: through the MCP tools the app serves, it lists the chats, types a command into one and reads the reply. There is no socket and no CLI of its own; the tools reach the client through whatever MCP host the app registers them with (adhd's `/mcp`, or the app's own endpoint).

`TerminalChatDirectory` is the set of Terminal Chats the app has open, by id. A chat pane adds itself when it is made and removes itself when it is discarded; sessions are held weakly besides, so a pane that goes without saying so drops out instead of lingering. Each entry pairs a listing (a short stable id, the project name, the directory and the pane number) with the chat session.

`TerminalChatDirectoryToolSource` is a `ChatToolSource` over any `TerminalChatListing` (the directory, or a fake in tests) that serves five tools: `list`, `run`, `wait`, `interrupt` and `screen`. Everything goes through the chat, never the terminal, so it shows in the chat's transcript as it happens, and a chat connected to a private terminal reads back only what that terminal shows, with its privacy words in place of the real ones. `TerminalChatDriving` is the slice of `TerminalChatSession` the tools call, so they can be exercised against a fake chat.
## Behavioral Requirements

- **directory-add**: `add(_:as:)` MUST store the session under its listing's id, replacing any entry already under that id.
- **directory-remove**: `remove(id:)` MUST delete the entry for that id and MUST do nothing for an unknown id.
- **directory-weak**: The directory MUST hold each session weakly, and a session that has been released MUST drop out of the listing the next time the chats are read.
- **chat-id**: `chatID(forNode:)` MUST return the first 8 characters of the node id's UUID string, lowercased.
- **chats-sorted**: `chatEntries` MUST be ordered by project name, then by pane number, using the project names as listed (after concealment).
- **chats-connected**: A chat's `connected` flag MUST be true exactly when its session has a terminal.
- **chats-presentable**: A chat's project and directory path MUST be passed through the connected terminal's `presentable` text, so a private terminal conceals them as its screen does, and MUST be listed as given when the session has no terminal.
- **five-tools**: `toolDefinitions()` MUST offer exactly `list`, `run`, `wait`, `interrupt` and `screen`; `run` MUST require `command`, and `chat` MUST be optional on every tool that takes it.
- **unknown-tool**: A call naming any other tool MUST answer "Unknown tool <name>." as an error.
- **bad-arguments**: Arguments that do not decode MUST answer an error naming the tool; empty arguments MUST be treated as no arguments.
- **list-action**: `list` MUST answer every chat as pretty-printed JSON with sorted keys, with no chat resolved and never as an error.
- **resolve-chat**: Every other tool MUST resolve its target with `TerminalChatControl.resolve`, by prefix or the only chat when none is named, and MUST answer the resolution error's message as an error when there are none or several.
- **not-connected**: When the resolved chat has no terminal, the answer MUST be the error "Terminal Chat <id> is not connected to a terminal — use Connect to Terminal in its pane's Settings."
- **settle-clamp**: The settle time MUST be the requested seconds, or 1.5 when none, raised to at least 0.1 and capped at 60, expressed in whole milliseconds.
- **timeout-clamp**: The timeout MUST be the requested seconds, or 60 for run and wait and 10 for interrupt when none, raised to at least 0.1 and capped at 600, expressed in whole milliseconds.
- **interrupt-default-timings**: `interrupt` MUST ignore any settle or timeout it is given and use the defaults.
- **run-needs-command**: A run with no command or an empty command MUST be answered with the error "run needs a command.", and nothing MUST be typed.
- **run-action**: `run` MUST type the command into the chat and answer the reply, using the settle and timeout.
- **wait-action**: `wait` MUST answer more output from the chat, using the settle and timeout.
- **interrupt-action**: `interrupt` MUST send the interrupt through the chat and answer what the terminal printed.
- **screen-action**: `screen` MUST answer the last lines of the terminal's screen, 40 lines when the call names none, and an empty string when the session has no screen text.
- **through-chat**: Commands MUST go through the chat session, never straight to the terminal.
- **concealed-reply**: A reply from a chat connected to a private terminal MUST be what that terminal shows, with its privacy words in place of the real ones.
- **main-actor**: The directory MUST be used only from the main actor; the tool source hops to the main actor to read it and to drive a chat.
- **lines-bounds**: The tool source MUST pass the requested line count to the session unclamped; the session raises it to at least 1 and returns at most the lines it has.
- **caller-authorization**: NEEDS REVIEW: The tool source does no authorization of its own; who may call it is the MCP host's bearer-token check, so any client holding the host's token can type into any connected chat, including a private one; evidence that settles it is a product decision on whether the host's token is the intended limit.
## Appearance

Not applicable: the directory and the server are non-visual; they draw nothing.

## States

| State | Appearance change |
|-------|------------------|
| Chat unconnected | Listed with `connected` false; every tool but `list` answers the not-connected error. |
| Chat connected | Listed with `connected` true; run, wait, interrupt and screen are served. |
| Chat released | Dropped from the next listing without a call to remove. |
| Pressed | Not applicable: the types have no interactive element. |
| Disabled | Not applicable: no enabled flag. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long run is reported by the session's own timeout. |
## Accessibility

Not applicable: the types are not a user interface; they present no view, control or text to a user. The listed project and directory text is what the terminal would show, for a client program to read.

## Conformance Test Vectors

`TerminalChatDirectoryToolSourceTests` drives the tool source over a fake listing of fake chats; the directory's vectors are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-control-server-001 | chat-id | Node UUID `ABCDEF12-3456-7890-ABCD-EF1234567890` | `abcdef12`. |
| terminal-chat-control-server-002 | directory-add, chats-sorted | Add chats (project "b", pane 1), (project "a", pane 2), (project "a", pane 1) | Listing order: ("a", 1), ("a", 2), ("b", 1). |
| terminal-chat-control-server-003 | directory-add | Add two sessions under the same id | One chat, the second session. |
| terminal-chat-control-server-004 | directory-remove | Remove an id, then an unknown id | The chat is gone; the unknown id does nothing. |
| terminal-chat-control-server-005 | directory-weak | Add a session, release it, list | The listing is empty. |
| terminal-chat-control-server-006 | chats-presentable, chats-connected | A private session with a terminal and words mike to robin; project "mike" | The chat lists project "robin" and `connected` true. |
| terminal-chat-control-server-007 | chats-presentable, chats-connected | A session with no terminal | The chat lists its text as given with `connected` false. |
| terminal-chat-control-server-008 | five-tools | `toolDefinitions()` | The names list, run, wait, interrupt, screen. |
| terminal-chat-control-server-009 | list-action | `list` with `{}` | A JSON array of every chat; not an error. |
| terminal-chat-control-server-010 | resolve-chat | `screen` with a prefix matching one chat; matching two; matching none; no chat with one open; no chat with two open | The one chat is served; "More than one Terminal Chat matches — choose one of: …"; "No Terminal Chat with id <prefix>."; the only chat is served; an error. |
| terminal-chat-control-server-011 | not-connected | `run` `{"chat":"ab","command":"ls"}` for a chat without a terminal | The error naming the chat id and Connect to Terminal. |
| terminal-chat-control-server-012 | run-needs-command | `run` with `{}` on a connected chat | "run needs a command." as an error; nothing typed. |
| terminal-chat-control-server-013 | run-action, through-chat | `run` `{"command":"ls"}` | The chat's run is called with `ls`; the answer is its output. |
| terminal-chat-control-server-014 | settle-clamp, timeout-clamp | `run` with no timings; with settle 0.01 and timeout 9999 | 1500 ms and 60000 ms; 100 ms and 600000 ms. |
| terminal-chat-control-server-015 | interrupt-default-timings, interrupt-action | `interrupt` with settle 9 and timeout 9 | The chat's interrupt-and-wait is called with 1500 ms and 10000 ms. |
| terminal-chat-control-server-016 | screen-action | `screen` with no `lines`; with `lines` 5; for a chat with no screen | 40 lines asked; 5 lines asked; output "". |
| terminal-chat-control-server-017 | unknown-tool | A call to `type` | "Unknown tool type." as an error. |
| terminal-chat-control-server-018 | concealed-reply | A chat on a private terminal replies with its screen | The answer holds the alias, never the real text. |
## Edge Cases

- **Null / empty input**: No chat named with exactly one chat resolves to that chat; with none it answers "There is no Terminal Chat open." (MUST). An empty command on run is refused (MUST). A missing `lines` means 40 (MUST). Empty arguments are no arguments (MUST).
- **Boundary values**: Settle below 0.1 seconds becomes 0.1, above 60 becomes 60; timeout above 600 becomes 600 (MUST). A chat id prefix that matches two chats is refused with the matching ids (MUST). `lines` is not clamped by the tool source; the session floors it at 1 and returns at most the screen's lines (`lines-bounds`).
- **Concurrent access**: The directory is main-actor only; the chats read at the start of a call are held strongly for that call, so a chat released meanwhile still answers from that snapshot and drops from the next listing (MUST). Two simultaneous calls each run through the main actor in turn.
- **Error states**: Bad arguments, an unknown tool, an unknown chat, an unconnected chat and an empty command each give an error answer (`isError` true) rather than a thrown error (MUST).
- **Offline / disconnected state**: Not applicable: the tools are called in process by the MCP host; reaching that host is its concern.
- **Unconnected private chat**: The chat is listed, with `connected` false and its project and directory as given, because there is no terminal to present them; the source comment says nothing is listed for such a chat, but the code lists it, so a port MUST follow the code's behavior.
- **Long commands**: A command that outlasts the timeout is reported by the session as still running; `wait` then returns more output (MUST, per the session's own contract).
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directory` | `any TerminalChatListing` | none (required) | The chats the tools answer from; a `TerminalChatDirectory` in an app. |
| settle | seconds | 1.5, max 60 | Seconds output must stop for before a reply is complete (from the shared defaults). |
| timeout | seconds | 60 for run and wait, 10 for interrupt, max 600 | Longest a run or wait waits (from the shared defaults). |
| lines | `Int` | 40 | Lines a screen call returns. |
## Deep Linking

Not applicable: the tools define no URL scheme; they are reached through the MCP host that serves them.
## Localization

Not applicable: the error strings are protocol messages read by a command-line client, written in English in the source and not looked up in a localization table.

## Accessibility Options

Not applicable: the types present no UI and respond to no accessibility display option.

## Feature Flags

Not applicable: the types contain no feature-flag reference.

## Analytics

Not applicable: the types contain no analytics call.

## Privacy

- **Data collected**: Commands typed into a chat and the terminal's replies; the chat list with project and directory text.
- **Storage**: Nothing persisted by these types; the directory holds listings and weak session references in memory.
- **Transmission**: In process, to the MCP host that serves the tools; the host decides who may call (a bearer token on a loopback port for adhd and the app's endpoint).
- **Retention**: A call lives for its duration; the directory entry lives until removed or the session is released.
- **Concealment**: Project and directory text and terminal replies are passed through the connected terminal's presentable text, so a private terminal's privacy words replace the real ones, as on its screen.
- **Security**: The tool source has no authority check of its own; see the open question on `caller-authorization`.
## Logging

Not applicable: the types call no logging API, so calls, commands and replies are never written to a log by them.
## Platform Notes

- **SwiftUI**: Source is `macOS/Features/TerminalSession/TerminalChatDirectory.swift` and `TerminalChatDirectoryToolSource.swift`, with no view code, so a SwiftUI app uses them unchanged; create the directory once, pass it to panes and register `TerminalChatDirectoryToolSource(directory:)` with the app's MCP host. The protocol is `Core/Terminal/TerminalChatControl.swift`.
- **Compose**: Hold a main-dispatcher-confined map of `WeakReference` chat entries, expose each tool through the app's MCP tool registry, and use `withTimeout` for the settle and timeout values.
- **React/Web**: Hold chats in a `Map` of `WeakRef`, register the five tools with the MCP server SDK's `server.tool(...)`, and clamp numbers with `Math.min(Math.max(...))`.
- **AppKit / UIKit**: The source is main-actor Swift using `Foundation` only; the tool source is `@unchecked Sendable` and hops to the main actor for every read and call.
- **WinUI 3**: Keep the directory as a `Dictionary<string, (Listing, WeakReference<TerminalChatSession>)>` on the UI thread, marshal each tool call there with `DispatcherQueue.TryEnqueue` and a `TaskCompletionSource`, and clamp settle and timeout with `Math.Clamp` into a `TimeSpan`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalChatDirectory.swift` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalChatDirectoryToolSource.swift` | unverified |

## Design Decisions

**Decision**: Drive chats through the chat session, never the terminal.
**Rationale**: The source says it shows in the chat's transcript as it happens, and a chat connected to a private terminal reads back only what that terminal shows, with privacy words in place of the real ones.
**Approved**: pending

**Decision**: Hold sessions weakly and also have panes add and remove themselves.
**Rationale**: The source says a pane that goes without saying so drops out rather than lingering; the weak reference covers the pane that forgets to remove itself.
**Approved**: pending

**Decision**: Serve the chats as MCP tools rather than over a socket of the app's own.
**Rationale**: Apps suite Phase 4 retires the per-app Unix socket and the `adterm` client: the tools reach Claude Code through the MCP host the app already registers with, which carries the bearer-token check, so the app has one door rather than two.
**Approved**: pending

**Decision**: Put the directory behind `TerminalChatListing` and the session behind `TerminalChatDriving`.
**Rationale**: The tool source can then be exercised against fakes, without a terminal or a pane.
**Approved**: pending

**Decision**: Clamp settle and timeout, but not line count, and give `interrupt` the default timings only.
**Rationale**: The source clamps the two durations to a floor of 0.1 seconds and the shared maxima; the session floors `lines` itself; Control-C either works quickly or not at all.
**Approved**: pending

**Decision**: List an unconnected chat with its text as given.
**Rationale**: The code's `presentable` falls back to the plain text when the session has no terminal, while its comment says nothing is listed for a chat not yet unlocked; the recipe records the behavior of the code and flags the mismatch.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | access-patterns |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | partial | security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

Separation of concerns passes: the protocol and defaults live in the control type, the transport in the MCP host and the typing in the chat session, while these types hold the directory and map tool calls to session calls. Unit-test coverage is partial: `TerminalChatDirectoryToolSourceTests` covers the tool source over fakes, and no test exercises the directory itself. Timeout configuration passes because settle and timeout are clamped to named bounds with per-action defaults. Server-side authorization is partial: the MCP host's bearer token decides who may call, and any holder can drive any connected chat, the open question on `caller-authorization`. No PII in logs passes because the types call no logging API.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-23 | Mike Fullerton | Apps suite Phase 4: the socket server is gone; Terminal Chats are served as five MCP tools by TerminalChatDirectoryToolSource over TerminalChatDirectory. |
