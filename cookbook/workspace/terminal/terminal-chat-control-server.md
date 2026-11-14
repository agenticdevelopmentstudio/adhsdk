---
id: 80fecda2-6440-497a-ba28-c77eb05cc996
title: "Terminal Chat Control Server"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An app-side socket server and chat directory that let adterm in another terminal list Terminal Chats, type into one and read its concealed reply."
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

# Terminal Chat Control Server

## Overview

This source holds two main-actor types that let a process outside the app drive the app's Terminal Chats, over the protocol [adhsdk.ingredient.foundation.terminal.terminal-chat-control](cookbook:b71b349b-5c60-41f4-b664-49085ac5d988) defines. The client is `adterm`, run by Claude Code in another terminal: it lists the chats, types a command into one and reads the reply.

`TerminalChatDirectory` is the set of Terminal Chats the app has open, by id. A chat pane adds itself when it is made and removes itself when it is discarded; sessions are held weakly besides, so a pane that goes without saying so drops out instead of lingering. Each entry pairs a listing (a short stable id, the project name, the directory and the pane number) with the chat session.

`TerminalChatControlServer` listens on a Unix-domain socket named for the process id and answers one JSON request per connection from the directory. Everything goes through the chat, never the terminal, so it shows in the chat's transcript as it happens, and a chat connected to a private terminal reads back only what that terminal shows, with its privacy words in place of the real ones. The transport is `UnixSocketLineServer`: it makes the socket file owner-only, refuses a peer whose user id is not the server's own, reads one newline-delimited line per connection and answers with one line.

## Behavioral Requirements

- **directory-add**: `add(_:as:)` MUST store the session under its listing's id, replacing any entry already under that id.
- **directory-remove**: `remove(id:)` MUST delete the entry for that id and MUST do nothing for an unknown id.
- **directory-weak**: The directory MUST hold each session weakly, and a session that has been released MUST drop out of the listing the next time the chats are read.
- **chat-id**: `chatID(forNode:)` MUST return the first 8 characters of the node id's UUID string, lowercased.
- **chats-sorted**: The chats MUST be ordered by project name, then by pane number, using the project names as listed (after concealment).
- **chats-connected**: A chat's `connected` flag MUST be true exactly when its session has a terminal.
- **chats-presentable**: A chat's project and directory path MUST be passed through the connected terminal's `presentable` text, so a private terminal conceals them as its screen does, and MUST be listed as given when the session has no terminal.
- **server-start**: `start()` MUST prepare the socket directory, listen at the socket for this process's id in that directory and keep the listener.
- **server-start-idempotent**: Calling `start()` while a server already exists MUST do nothing.
- **server-start-error**: An error from preparing the directory or from starting the listener MUST propagate to the caller, and no server MUST be kept.
- **server-stop**: `stop()` MUST stop the listener and release it, and MUST be safe when not started.
- **answer-decode-failure**: A request that does not decode as a control request MUST be answered with the error "Not a Terminal Chat request."
- **answer-app-name**: Every answer to a request that decodes, success or failure, MUST carry the app name the server was created with; the decode-failure, shutting-down and encode-fallback answers carry none.
- **answer-shutting-down**: A request that arrives after the server object is gone MUST be answered with the error "The app is shutting down."
- **answer-encode-fallback**: When the answer cannot be encoded, the server MUST send the JSON object with the error "Could not encode the reply."
- **list-action**: A list request MUST return every chat in the directory, with no chat resolved.
- **resolve-chat**: Any other action MUST resolve its target by prefix, or the only chat when none is named, and MUST answer the resolution error's message when there are none or several ("No Terminal Chat with id <prefix>." for a named prefix that matches none, "There is no Terminal Chat open." when none is named and none exist, and "More than one Terminal Chat matches — choose one of: <ids>" for several).
- **not-connected**: When the resolved chat has no terminal, the answer MUST be the error "Terminal Chat <id> is not connected to a terminal — use Connect to Terminal in its pane's Settings."
- **settle-clamp**: The settle time MUST be the requested seconds, or 1.5 when none, raised to at least 0.1 and capped at 60, expressed in whole milliseconds.
- **timeout-clamp**: The timeout MUST be the requested seconds, or 60 for run and wait and 10 for interrupt when none, raised to at least 0.1 and capped at 600, expressed in whole milliseconds.
- **run-needs-command**: A run request with no command or an empty command MUST be answered with the error "run needs a command.", and nothing MUST be typed.
- **run-action**: A run request MUST type the command into the chat and answer with the chat id and the reply, using the settle and timeout.
- **wait-action**: A wait request MUST answer with the chat id and more output from the chat, using the settle and timeout.
- **interrupt-action**: An interrupt request MUST send the interrupt through the chat and answer with the chat id and what the terminal printed, using the settle and timeout.
- **screen-action**: A screen request MUST answer with the chat id and the last lines of the terminal's screen, 40 lines when the request names none, and an empty string when the session has no screen text; the session drops trailing blank rows before taking the last lines.
- **through-chat**: Commands MUST go through the chat session, never straight to the terminal.
- **concealed-reply**: A reply from a chat connected to a private terminal MUST be what that terminal shows, with its privacy words in place of the real ones.
- **socket-owner-only**: The listening socket MUST be reachable by this user alone: the directory owner-only, the socket file owner-only and a peer with another user id refused.
- **slow-client-timeout**: An accepted connection MUST have a 10 second limit on each read and write, so a client that sends nothing is dropped.
- **one-request-per-connection**: Each connection MUST carry one request line and receive one answer line, then close.
- **request-size-cap**: A request longer than 1 MiB MUST be dropped unanswered.
- **main-actor**: The directory and the server MUST be used only from the main actor; the socket handler hops to the main actor to answer.
- **lines-bounds**: The server MUST pass the requested line count to the session unclamped; the session raises it to at least 1 and returns at most the lines it has, so zero or a negative number yields one line and a very large number yields every line of the screen (trailing blank rows are dropped first).
- **caller-authorization**: NEEDS REVIEW: Not implemented in source. Beyond the same-user peer check, the server does not authenticate which process or user session connects, so any process of the same user can type into any connected chat, including a private one; evidence that settles it is a product decision on whether the same-user boundary is the intended limit.

## Appearance

Not applicable: the directory and the server are non-visual; they draw nothing.

## States

| State | Appearance change |
|-------|------------------|
| Server stopped (default) | No socket exists; the object holds no listener. |
| Server listening | The socket file for this process's id exists, owner-only, and answers one request per connection. |
| Chat unconnected | Listed with `connected` false; a command action is refused with the not-connected error. |
| Chat connected | Listed with `connected` true; run, wait, interrupt and screen are served. |
| Chat released | Dropped from the next listing without a call to remove. |
| Pressed | Not applicable: the types have no interactive element. |
| Disabled | Not applicable: no enabled flag. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long run is reported by the session's own timeout. |

## Accessibility

Not applicable: the types are not a user interface; they present no view, control or text to a user. The listed project and directory text is what the terminal would show, for a client program to read.

## Conformance Test Vectors

The repository has no test that names these types. The vectors are derived from the source; the directory holds sessions that are test doubles, and a request is the JSON line a client sends.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-control-server-001 | chat-id | Node UUID `ABCDEF12-3456-7890-ABCD-EF1234567890` | `abcdef12`. |
| terminal-chat-control-server-002 | directory-add, chats-sorted | Add chats (project "b", pane 1), (project "a", pane 2), (project "a", pane 1) | Listing order: ("a", 1), ("a", 2), ("b", 1). |
| terminal-chat-control-server-003 | directory-add | Add two sessions under the same id | One chat, the second session. |
| terminal-chat-control-server-004 | directory-remove | Remove an id, then an unknown id | The chat is gone; the unknown id does nothing. |
| terminal-chat-control-server-005 | directory-weak | Add a session, release it, list | The listing is empty. |
| terminal-chat-control-server-006 | chats-presentable, chats-connected | A private session with a terminal and words mike to robin; project "mike" | The chat lists project "robin" and `connected` true. |
| terminal-chat-control-server-007 | chats-presentable, chats-connected | A session with no terminal | The chat lists its text as given with `connected` false. |
| terminal-chat-control-server-008 | list-action | `{"action":"list"}` | A response with every chat and the app name. |
| terminal-chat-control-server-009 | answer-decode-failure, answer-app-name | The line `not json` | `{"error":"Not a Terminal Chat request."}` with no app name; a decodable request that fails (for example run with no command) carries `"app":"<appName>"`. |
| terminal-chat-control-server-010 | resolve-chat | `{"action":"screen"}` with no chats; with two chats; with a chat id prefix that matches one | "There is no Terminal Chat open."; "More than one Terminal Chat matches — choose one of: …"; the one chat is served. |
| terminal-chat-control-server-011 | not-connected | `{"action":"run","chat":"ab","command":"ls"}` for a chat without a terminal | The error naming the chat id and Connect to Terminal. |
| terminal-chat-control-server-012 | run-needs-command | `{"action":"run"}` and `{"action":"run","command":""}` on a connected chat | "run needs a command." for each; nothing typed. |
| terminal-chat-control-server-013 | run-action, through-chat | `{"action":"run","command":"ls"}` | The session's run is called with `ls`; the answer carries the chat id and its output. |
| terminal-chat-control-server-014 | settle-clamp | `settle` 0.01, 1000 and absent | 100 ms, 60000 ms and 1500 ms. |
| terminal-chat-control-server-015 | timeout-clamp | `timeout` absent for run and for interrupt; 9999 | 60000 ms for run, 10000 ms for interrupt, 600000 ms for 9999. |
| terminal-chat-control-server-016 | wait-action, interrupt-action | A wait and an interrupt request | The session's wait and interrupt-and-wait are called; each answer carries the chat id and output. |
| terminal-chat-control-server-017 | screen-action | A screen request with no `lines`; with `lines` 5; for a session with no screen | 40 lines asked; 5 lines asked; output "". |
| terminal-chat-control-server-018 | server-start, server-start-idempotent | `start()` twice | One listener at `<socketDirectory>/<pid>.sock`. |
| terminal-chat-control-server-019 | server-start-error | The socket directory cannot be created | `start()` throws and no server is kept; a later `start()` tries again. |
| terminal-chat-control-server-020 | server-stop | `stop()` before and after `start()` | No error either time; the socket file is gone after the second. |
| terminal-chat-control-server-021 | answer-shutting-down | The server object is released while a request is in flight | `{"error":"The app is shutting down."}`. |
| terminal-chat-control-server-022 | socket-owner-only, request-size-cap, one-request-per-connection | Check the socket file mode; connect as another user; send 2 MiB; send two lines | Mode 0600 in a 0700 directory; the peer is refused; no answer; the first line is answered and the connection closes. |
| terminal-chat-control-server-023 | concealed-reply | A chat on a private terminal replies with its screen | The answer holds the alias, never the real text. |

## Edge Cases

- **Null / empty input**: No chat named with exactly one chat resolves to that chat; with none it answers "There is no Terminal Chat open." (MUST). An empty command on run is refused (MUST). A missing `lines` means 40 (MUST).
- **Boundary values**: Settle below 0.1 seconds becomes 0.1, above 60 becomes 60; timeout above 600 becomes 600 (MUST). A chat id prefix that matches two chats is refused with the matching ids (MUST). `lines` is not clamped by the server; the session floors it at 1 and returns at most the screen's lines (`lines-bounds`).
- **Concurrent access**: The directory and the server are main-actor only; the chats read at the start of a request are held strongly for that request, so a chat released meanwhile still answers from that snapshot and drops from the next listing (MUST). Two simultaneous requests each run through the main actor in turn, and the transport answers each connection on its own task.
- **Error states**: A malformed request, an unknown chat, an unconnected chat, an empty command and a failed encode each give an error answer rather than a dropped connection, except an oversize request, which is dropped (MUST).
- **Offline / disconnected state**: Not applicable: the channel is a local socket, not a network. A client whose app is not running finds no socket for a live process; a stale socket file from a dead process is removed when the directory is prepared (MUST).
- **Unconnected private chat**: The chat is listed, with `connected` false and its project and directory as given, because there is no terminal to present them; the source comment says nothing is listed for such a chat, but the code lists it, so a port MUST follow the code's behavior.
- **Server restart**: `stop()` then `start()` makes a new listener at the same path; whatever file is at the path is removed first.
- **Long commands**: A command that outlasts the timeout is reported by the session as still running; `wait` then returns more output (MUST, per the session's own contract).
- **Shutdown during a request**: The request is answered with "The app is shutting down." (MUST).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directory` | `TerminalChatDirectory` | none (required) | The chats the server answers from. |
| `appName` | `String` | none (required) | Reported in every answer so a client talking to several apps can tell them apart. |
| settle | seconds | 1.5, max 60 | Seconds output must stop for before a reply is complete (from the shared defaults). |
| timeout | seconds | 60 for run and wait, 10 for interrupt, max 600 | Longest a run or wait waits (from the shared defaults). |
| lines | `Int` | 40 | Lines a screen request returns. |

## Deep Linking

Not applicable: the server defines no URL scheme; it listens on a socket path named for the process id.

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
- **Storage**: Nothing persisted by these types; the directory holds listings and weak session references in memory, and the socket file lives in the socket directory while the app runs.
- **Transmission**: Over a local Unix-domain socket to a process of the same user only; nothing leaves the machine.
- **Retention**: A request lives for one connection; the directory entry lives until removed or the session is released.
- **Concealment**: Project and directory text and terminal replies are passed through the connected terminal's presentable text, so a private terminal's privacy words replace the real ones, as on its screen.
- **Security**: The directory is owner-only (mode 0700) and the socket file owner-only (mode 0600), and a peer whose user id differs is refused, because a local HTTP port is open to every process on the machine; a request over 1 MiB is dropped; a stale socket from a dead process is removed. There are no tokens or sessions; authority is being the same user. See the open question on `caller-authorization`.

## Logging

Not applicable: the types call no logging API, so requests, commands and replies are never written to a log by them.

## Platform Notes

- **SwiftUI**: Source is `macOS/Features/TerminalSession/TerminalChatControlServer.swift`, with no view code, so a SwiftUI app uses it unchanged; create the directory once and pass it to panes. The transport is `Core/RPC/UnixSocketLineServer.swift` and the protocol is `Core/Terminal/TerminalChatControl.swift`.
- **Compose**: Use a `LocalServerSocket` with a `LocalSocketAddress` in the abstract or file namespace, restrict by `getpeercred` credentials, one `Mutex` or main-dispatcher-confined map of `WeakReference` chat entries, and a `withTimeout` for the settle and timeout values.
- **React/Web**: A browser cannot host a socket; a Node host would use `net.createServer` on a Unix socket path with mode 0600 (`fs.chmod`), compare the peer by `SO_PEERCRED`-equivalent checks where available, hold chats in a `Map` of `WeakRef`, and clamp numbers with `Math.min(Math.max(...))`.
- **AppKit / UIKit**: The source is main-actor Swift using `Foundation` only; the transport uses `DispatchSource` and `getpeereid`. iOS has no cross-process Unix sockets between apps, so the type does not apply there.
- **WinUI 3**: Use a named pipe instead of a socket: `NamedPipeServerStream` named `TerminalChat\<pid>` with a `PipeSecurity` that grants `FullControl` to the current user's `WindowsIdentity.GetCurrent().User` only, and reject others with `RunAsClient` or the pipe's own ACL. Read one UTF-8 line (cap at 1 MiB with `StreamReader` and a counted read), answer one line and dispose the stream. Keep the directory as a `Dictionary<string, (Listing, WeakReference<TerminalChatSession>)>` on the UI thread and marshal each request there with `DispatcherQueue.TryEnqueue` and a `TaskCompletionSource`. Clamp settle and timeout with `Math.Clamp` and convert to a `TimeSpan` via `TimeSpan.FromMilliseconds`. Delete stale pipes is unnecessary because pipes vanish with their process; the pid-named pipe lets a client enumerate hosts through `Directory.GetFiles(@"\\.\pipe\")`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalChatControlServer.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Drive chats through the chat session, never the terminal.
**Rationale**: The source says it shows in the chat's transcript as it happens, and a chat connected to a private terminal reads back only what that terminal shows, with privacy words in place of the real ones.
**Approved**: pending

**Decision**: Hold sessions weakly and also have panes add and remove themselves.
**Rationale**: The source says a pane that goes without saying so drops out rather than lingering; the weak reference covers the pane that forgets to remove itself.
**Approved**: pending

**Decision**: Use a Unix-domain socket instead of a localhost port.
**Rationale**: The source says a socket file is reachable only by whoever can reach its path, the server makes it owner-only and refuses another user's peer, whereas a localhost HTTP port is open to every process on the machine.
**Approved**: pending

**Decision**: Clamp settle and timeout, but not line count.
**Rationale**: The source clamps the two durations to a floor of 0.1 seconds and the shared maxima and leaves `lines` as requested; the server leaves `lines` as requested because the session floors it at 1 and returns at most the lines it has.
**Approved**: pending

**Decision**: List an unconnected chat with its text as given.
**Rationale**: The code's `presentable` falls back to the plain text when the session has no terminal, while its comment says nothing is listed for a chat not yet unlocked; the recipe records the behavior of the code and flags the mismatch.
**Approved**: pending

**Decision**: Answer every failure with a protocol error message rather than closing the connection, naming the app on every answer to a decodable request.
**Rationale**: The source sets the app name on every response to a decoded request and builds failures from the shared `failure` form so a client talking to several apps can tell which answered; the decode-failure, shutting-down and encode-fallback answers carry no app name.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | access-patterns |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | partial | security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

Separation of concerns passes: the protocol and defaults live in the control type, the socket in the transport and the typing in the chat session, while these types hold the directory and map requests to session calls. Unit-test coverage fails because no test in the repository exercises the directory or the server. Timeout configuration passes because settle and timeout are clamped to named bounds with per-action defaults. Server-side authorization is partial: the socket is owner-only and a peer of another user id is refused, but any process of the same user can drive any connected chat, the open question on `caller-authorization`. No PII in logs passes because the types call no logging API.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
