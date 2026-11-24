---
id: d4944b9e-11a7-481a-b3c7-0e9a7454774c
title: "Terminal Chat Tool Source"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Three tools a persona chat uses to run a command in, wait on and interrupt a terminal, reached through a Terminal Chat looked up on every call."
platforms:
  - swift
  - macos
tags:
  - terminal
  - terminal-chat
  - tools
  - privacy
depends-on:
  - b71b349b-5c60-41f4-b664-49085ac5d988
related: []
references: []
approved-by: ""
approved-date: ""
---

# Terminal Chat Tool Source

## Overview

`TerminalChatToolSource` is a chat tool source: it advertises tool definitions to a persona's model and runs the calls the model makes. Its three tools let a persona work a terminal: `run_terminal_command` types a command and returns what the terminal printed until it went quiet, `wait_for_terminal_output` returns more output from a command that was still running, and `interrupt_terminal` sends Control-C and returns what the command printed.

The tools reach the terminal through a Terminal Chat session, never the terminal itself. Connected to a private terminal, the persona sees only that terminal's privacy words, never the real ones, because the session reads replies off the terminal's own screen. The Terminal Chat is looked up on every call, by a closure the host supplies, not held, so connecting one after the persona chat opened, or closing it, takes effect on the next tool call. The closure runs on the main actor, where panes live.

The tool names are this source's own. The settle, timeout and interrupt-timeout defaults the calls take are the session's, which reads them from [adhsdk.ingredient.foundation.terminal.terminal-chat-control](cookbook:b71b349b-5c60-41f4-b664-49085ac5d988); the reply text is the session's, and the session the tools call is the Terminal Chat session recipe in this folder.

## Behavioral Requirements

- **tool-names**: The three tools MUST be named `run_terminal_command`, `wait_for_terminal_output` and `interrupt_terminal`.
- **definitions-all**: `toolDefinitions()` MUST return all three definitions on every call, in the order run, wait, interrupt, whether or not a Terminal Chat is connected.
- **run-definition**: The run tool's definition MUST describe typing a command into the user's terminal and pressing Return, returning what the terminal printed until it went quiet including the following shell prompt, and MUST tell the model that some names in the output are pseudonyms to be used as given because they are translated on the way in.
- **run-schema**: The run tool's schema MUST be an object with one required string property `command`, described as the command line to run.
- **wait-definition**: The wait tool's definition MUST describe waiting for more output from a command still running when the run tool returned, and its schema MUST be an object with no properties and none required.
- **interrupt-definition**: The interrupt tool's definition MUST describe sending Control-C to stop the running command and returning what it printed, and its schema MUST be an object with no properties and none required.
- **resolve-per-call**: `callTool` MUST look up the Terminal Chat through the supplied closure on every call, on the main actor, and MUST NOT keep the result.
- **no-chat**: When the closure answers nil, every tool call MUST return an error whose content asks the user to add a Terminal Chat pane to the tab and turn on Connect to Terminal Chat in the pane's Settings, and MUST do nothing else.
- **run-call**: A run call MUST pass the command to the session's `run` with its default settle and timeout and return the reply as a non-error.
- **run-needs-command**: A run call whose arguments do not decode as a JSON object, or whose `command` is missing, not a string or empty, MUST return the error `run_terminal_command needs a non-empty "command".` and MUST NOT type anything.
- **wait-call**: A wait call MUST return the session's `waitForOutput` result with its default settle and timeout as a non-error.
- **interrupt-call**: An interrupt call MUST return the session's `interruptAndWait` result with its default settle and interrupt timeout as a non-error.
- **unknown-tool**: A call naming any other tool MUST return the error "Unknown tool: <name>" after the Terminal Chat has been found.
- **no-chat-before-unknown**: The no-Terminal-Chat error MUST be returned before the tool name is checked, so an unknown name with no chat answers with the missing-chat error.
- **ignore-extra-arguments**: Arguments other than `command` on a run call, and any arguments on a wait or interrupt call, MUST be ignored.
- **session-text-passthrough**: The reply text, including a not-connected or still-running line the session produced, MUST be returned unchanged as a non-error; only this source's own failures are errors.
- **sendable**: The source MUST be callable from any task; it holds only the closure, and the closure's work happens on the main actor.
- **separate-concerns-tools**: The source MUST NOT type into a terminal, read a screen or conceal text itself; it only asks the Terminal Chat.

## Appearance

Not applicable: the source is non-visual; it supplies tool definitions and results to a persona chat, and its text is read by a model.

## States

| State | Appearance change |
|-------|------------------|
| No Terminal Chat connected | Every call returns the missing-chat error. |
| Terminal Chat connected | Run, wait and interrupt reach the session and return its text. |
| Chat connected or closed mid-conversation | The next call sees the change, because the lookup is per call. |
| Pressed | Not applicable: the source has no interactive element. |
| Disabled | Not applicable: no enabled flag; the missing-chat error stands in for it. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long command is reported by the session as still running. |

## Accessibility

Not applicable: the source is not a user interface; it presents no view, control or text to a user. The definitions are read by a model.

## Conformance Test Vectors

The repository has no test that names this type. The vectors are derived from the source; the resolve closure and the session are test doubles.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-tool-source-001 | tool-names, definitions-all | `toolDefinitions()` | Three definitions named run_terminal_command, wait_for_terminal_output, interrupt_terminal, in that order. |
| terminal-chat-tool-source-002 | run-schema | The run definition's schema | An object whose properties are only `command` (string) and whose required list is `["command"]`. |
| terminal-chat-tool-source-003 | wait-definition, interrupt-definition | The wait and interrupt schemas | Objects with empty properties and empty required lists. |
| terminal-chat-tool-source-004 | run-definition | The run description | Mentions typing and Return, the prompt in the output and that pseudonyms are used as given. |
| terminal-chat-tool-source-005 | no-chat | Any tool call with the closure returning nil | An error asking for a Terminal Chat pane and Connect to Terminal Chat. |
| terminal-chat-tool-source-006 | no-chat-before-unknown | `callTool` named "bogus" with no chat | The missing-chat error, not "Unknown tool". |
| terminal-chat-tool-source-007 | run-call | Run with `{"command":"ls"}` and a session that answers "files" | Content "files", not an error; the session was run with "ls". |
| terminal-chat-tool-source-008 | run-needs-command | Run with `{}`, `{"command":""}`, `{"command":5}` and `not json` | The needs-a-command error for each; nothing typed. |
| terminal-chat-tool-source-009 | wait-call | Wait with arguments `{"x":1}` | The session's wait output, not an error; arguments ignored. |
| terminal-chat-tool-source-010 | interrupt-call | Interrupt | The session's interrupt-and-wait output, not an error. |
| terminal-chat-tool-source-011 | unknown-tool | `callTool` named "bogus" with a chat | "Unknown tool: bogus", an error. |
| terminal-chat-tool-source-012 | resolve-per-call | Call with no chat, connect one, call again | The first call errors; the second reaches the session. |
| terminal-chat-tool-source-013 | session-text-passthrough | The session answers with the still-running line | That text, unchanged, as a non-error. |

## Edge Cases

- **Null / empty input**: A missing or empty command is refused (MUST). Empty arguments on wait and interrupt are fine (MUST).
- **Boundary values**: A very long command is passed through to the session unchanged.
- **Concurrent access**: The closure is awaited on the main actor on each call; two tool calls at once each look up the chat and the session ends the earlier wait when a new one begins.
- **Error states**: Missing chat, malformed or empty command and unknown tool each return an error result rather than throwing (MUST).
- **Offline / disconnected state**: Not applicable: the channel is a local terminal, not a network. A session with no terminal answers with its own not-connected text, which is returned as a non-error (MUST).
- **Chat closed mid-turn**: A later call finds no chat and returns the missing-chat error (MUST).
- **Private terminal**: The persona sees privacy words in replies, and what it types is translated on the way in by the terminal, not by this source (MUST).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `resolve` | `@MainActor @Sendable () -> TerminalChatSession?` | none (required) | Answers the Terminal Chat to talk to, or nil when there is none; read on the main actor. |
| settle and timeout | `Duration` | 1.5 s and 60 s (10 s for interrupt) | Taken from the session's defaults; this source passes none of its own. |

## Deep Linking

Not applicable: the source defines no URL scheme and has no screen to link to.

## Localization

Not applicable: the tool names, descriptions and error messages are read by a model and written in English in the source, not looked up in a localization table.

## Accessibility Options

Not applicable: the source presents no UI and responds to no accessibility display option.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data collected**: The commands a persona types and the replies it reads.
- **Storage**: None by this type.
- **Transmission**: The replies are returned to the persona's model through the chat; this type adds nothing else.
- **Retention**: None by this type.
- **Concealment**: Connected to a private terminal, the persona sees only that terminal's privacy words, never the real ones, because the session reads the terminal's own screen; the run description tells the model that pseudonyms in the output are to be used as given.
- **Security**: A persona with these tools can type any command into the connected shell; the source performs no authorization of its own.

## Logging

Not applicable: the source calls no logging API, so commands and replies are never written to a log by it.

## Platform Notes

- **SwiftUI**: Source is `macOS/Features/TerminalSession/TerminalChatToolSource.swift`, with no view code; the persona terminal chat view controller creates it with a closure that finds the pane's Terminal Chat. It conforms to `ChatToolSource` from the core framework and builds schemas with `ToolJSONSchema`.
- **Compose**: Implement the same tool-source interface with three tool definitions whose parameters are JSON Schema strings, and a `suspend` call that obtains the chat from a `suspend () -> TerminalChat?` function on `Dispatchers.Main`.
- **React/Web**: A web persona chat would define the three tools as JSON Schema entries and a handler that awaits a `() => Promise<TerminalChat | undefined>` supplied by the host, returning `{ content, isError }`.
- **AppKit / UIKit**: The source is Foundation-only Swift marked `@unchecked Sendable`, with the closure hop to `@MainActor`. iOS has no shell to connect to, so it does not apply there.
- **WinUI 3**: Implement `IChatToolSource` with a `Func<Task<TerminalChatSession?>>` that dispatches to the UI thread through `DispatcherQueue.TryEnqueue` and a `TaskCompletionSource`. Return `ToolDefinition` records with schemas built by `System.Text.Json.Nodes.JsonObject`, parse the arguments with `JsonDocument.Parse` inside a `try`, and return a `(string Content, bool IsError)` tuple.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/TerminalChatToolSource.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Reach the terminal through a Terminal Chat, not the terminal itself.
**Rationale**: The source says that connected to a private terminal the persona only ever sees that terminal's privacy words, never the real ones.
**Approved**: pending

**Decision**: Look the Terminal Chat up on every call and hold nothing.
**Rationale**: The source says connecting one after the persona chat opened, or closing it, takes effect on the next tool call.
**Approved**: pending

**Decision**: Always advertise all three tools, even when no chat is connected, and answer the missing chat inside the call.
**Rationale**: The definitions do not depend on the chat, so the persona can be told what to ask the user for; the missing-chat message names the pane to add and the setting to turn on.
**Approved**: pending

**Decision**: Return the session's text as a non-error, including its own not-connected and still-running lines.
**Rationale**: Only this source's own failures (no chat, no command, unknown tool) are errors; the session's text is the terminal's answer, for the persona to read and act on.
**Approved**: pending

**Decision**: Tell the model that pseudonyms in the output are to be used as given.
**Rationale**: The run description says names in the output are pseudonyms, translated on the way in, so the model must not try to recover the real ones.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

Separation of concerns passes: the source only defines tools and routes calls; typing, timing and concealment belong to the session and the terminal. Unit-test coverage fails because no test in the repository exercises this type. Explicit error handling passes because a missing chat, a bad command and an unknown tool each return an error result with a message that says what to do. No PII in logs passes because the source calls no logging API.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
