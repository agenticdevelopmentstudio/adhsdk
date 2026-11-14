---
id: 3c6285a6-4e5d-4299-9c37-7253eed7584d
title: "HostAppToolSource"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The two tools every host app offers over MCP: host_app_info, which reports name, version and plugins, and host_open_chat_window, which runs an injected callback."
platforms:
  - swift
  - macos
tags:
  - mcp
  - tool-source
  - host-app
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# HostAppToolSource

## Overview

`HostAppToolSource` is a final class conforming to `ChatToolSource` that gives a chat engine or an MCP host two tools every host application offers: `host_app_info`, which says what the host app is, and `host_open_chat_window`, which asks the host app to open a new AI chat window. Its source comment says it is "what `HostMCPServer` used to hard-code, now one source among several": the host server registers it like any other tool source.

The class holds four values given at construction: the app name, the app version, the names of loaded plugins, and a callback that opens a chat window. It keeps no other state and reads nothing from the environment. Both tools take no arguments. A call to any other tool name returns an error result rather than throwing.

## Behavioral Requirements

Construction

- **tool-source-conformance**: The component MUST conform to the host's tool-source contract (`ChatToolSource`), providing a tool-definition list and a call operation that takes a tool name, the argument bytes and an optional caller identifier.
- **construction-parameters**: The component MUST be constructed from an app name (string), an app version (string), an optional list of plugin names and an optional open-chat-window callback.
- **plugin-names-default**: When no plugin names are given, the plugin list MUST default to empty.
- **open-callback-default**: When no callback is given, the open-chat-window callback MUST default to one that does nothing.
- **open-callback-isolation**: The open-chat-window callback MUST be a main-actor-isolated, sendable closure that returns nothing.
- **concurrency-safety**: The component MUST be safe to share across concurrent callers; it MUST hold only immutable values fixed at construction (the source declares `Sendable`, and every stored property is a `let`).

Tool definitions

- **tool-list-order**: `toolDefinitions()` MUST return exactly two definitions, in this order: `host_app_info`, then `host_open_chat_window`.
- **info-description**: The `host_app_info` definition MUST carry the description "Returns the host app's name, version and loaded plugins."
- **open-description**: The `host_open_chat_window` definition MUST carry the description "Opens a new AI chat window in the host app."
- **empty-parameter-schema**: Both definitions MUST declare a JSON object schema with no properties.
- **names-are-bare**: The component MUST advertise and accept the unprefixed names; any prefix is added by the registering server and stripped before a call reaches the component.

Tool calls

- **info-result-format**: A call to `host_app_info` MUST return the three lines `Host: <appName>`, `Version: <appVersion>` and `Plugins: <plugins>` joined by a single line feed, with no trailing line feed.
- **info-plugins-joined**: In `host_app_info`, plugin names MUST be joined with a comma and a space, in the order they were given.
- **info-plugins-none**: In `host_app_info`, an empty plugin list MUST be written as `(none)`.
- **info-not-error**: A `host_app_info` call MUST return `isError` false.
- **open-invokes-callback**: A call to `host_open_chat_window` MUST invoke the open-chat-window callback exactly once and MUST wait for it to finish before returning.
- **open-result-text**: A `host_open_chat_window` call MUST return the text `Opened a new chat window.` with `isError` false.
- **open-reports-success-unconditionally**: A `host_open_chat_window` call MUST return the success text even when the callback is the default no-op, because the callback has no return value and cannot signal failure.
- **unknown-tool-error**: A call with any other tool name MUST return the text `unknown tool <name>` with `isError` true.
- **arguments-ignored**: The component MUST ignore the argument bytes; it MUST NOT parse or validate them, so malformed or non-empty arguments have no effect.
- **caller-ignored**: The component MUST ignore the caller identifier.
- **no-throw**: The call operation MUST NOT throw; every outcome is a returned content string and an error flag.
- **no-side-effects-for-info**: `host_app_info` MUST NOT invoke the open-chat-window callback.

## Appearance

Not applicable — this is a tool source that returns text, not a visual component.

## States

Not applicable — this is a stateless tool source, not a visual component. The class has no runtime state machine: its four stored values never change after construction.

## Accessibility

Not applicable — this is a tool source that returns text, not a visual component.

## Conformance Test Vectors

Derived from `HostAppToolSourceTests` where named; the rest are traced to the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| host-app-tool-source-001 | tool-list-order, info-description, open-description | `toolDefinitions()` on a source built with app name "Kitchen" (`testHostAppToolSourceAnswersInfoAndOpensChat`) | Two definitions with names `host_app_info`, `host_open_chat_window`, in that order, with the two descriptions above |
| host-app-tool-source-002 | empty-parameter-schema | `toolDefinitions()` | Both definitions' schemas are object schemas with an empty property map |
| host-app-tool-source-003 | info-result-format, info-plugins-joined, info-not-error | App name "Kitchen", version "2.0", plugins `["ClaudeAPI"]`; call `host_app_info` with `{}` | Content `Host: Kitchen\nVersion: 2.0\nPlugins: ClaudeAPI`, `isError` false (`testHostAppToolSourceAnswersInfoAndOpensChat`) |
| host-app-tool-source-004 | info-plugins-none, plugin-names-default | App name "Kitchen", version "2.0", no plugins; call `host_app_info` | Content `Host: Kitchen\nVersion: 2.0\nPlugins: (none)` (`testHostAppInfoSaysNoneWhenThereAreNoPlugins`) |
| host-app-tool-source-005 | info-plugins-joined | Plugins `["A", "B", "C"]`; call `host_app_info` | The third line is `Plugins: A, B, C` |
| host-app-tool-source-006 | open-invokes-callback, open-result-text | Callback increments a counter; call `host_open_chat_window` once | Content `Opened a new chat window.`, `isError` false, counter is 1 (`testHostAppToolSourceAnswersInfoAndOpensChat`) |
| host-app-tool-source-007 | open-callback-default, open-reports-success-unconditionally | Source built without a callback; call `host_open_chat_window` | Content `Opened a new chat window.`, `isError` false, nothing else happens |
| host-app-tool-source-008 | no-side-effects-for-info | Callback increments a counter; call `host_app_info` | Counter stays 0 |
| host-app-tool-source-009 | unknown-tool-error | Call name `nope` with `{}` | Content `unknown tool nope`, `isError` true |
| host-app-tool-source-010 | arguments-ignored, caller-ignored | Call `host_app_info` with argument bytes `not json` and caller `pane-7` | Same content and `isError` as with `{}` and no caller |
| host-app-tool-source-011 | unknown-tool-error | Call with the empty string as the name | Content `unknown tool ` (trailing space), `isError` true |
| host-app-tool-source-012 | names-are-bare | Call `host_open_chat_window` with a prefixed name such as `app_host_open_chat_window` | Content `unknown tool app_host_open_chat_window`, `isError` true |

## Edge Cases

- **Empty plugin list**: MUST render `(none)`; covered by `testHostAppInfoSaysNoneWhenThereAreNoPlugins`.
- **Plugin names with commas or line feeds**: MUST be written as given, joined with a comma and a space; the source does not escape them, so a name containing a line feed adds a line to the result.
- **Empty app name or version**: MUST be written as an empty value after the label; the source does not validate them.
- **Malformed argument bytes**: MUST be ignored; both tools take no arguments and the source never decodes them.
- **Unknown tool name, including empty**: MUST return `unknown tool <name>` with `isError` true, never a thrown error.
- **Callback that does nothing or fails to open a window**: the call MUST still report success; the callback returns nothing, so the source cannot observe the outcome.
- **Repeated `host_open_chat_window` calls**: each call MUST invoke the callback once; the source does not deduplicate or rate-limit, so two calls open two windows if the callback does.
- **Concurrent calls**: the class holds only immutable values, so concurrent calls do not interfere. The callback runs on the main actor, so concurrent open requests are serialised there and run one at a time.
- **Offline or disconnected state**: not applicable — the component performs no network or file operation; it only formats stored strings and calls the injected callback.
- **Error states from dependencies**: the only dependency is the callback, which cannot throw or return an error, so the call reports success regardless (open-reports-success-unconditionally).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `appName` | String | none (required) | Written on the `Host:` line of `host_app_info` |
| `appVersion` | String | none (required) | Written on the `Version:` line of `host_app_info` |
| `pluginNames` | Array of String | empty | Written on the `Plugins:` line, joined with a comma and a space, or `(none)` when empty |
| `openChatWindow` | main-actor sendable closure returning nothing | does nothing | Invoked once per `host_open_chat_window` call |

## Deep Linking

Not applicable: the source opens a chat window through an injected callback and defines no URL scheme or route.

## Localization

The source returns hardcoded English: the two tool descriptions, the `Host:`, `Version:` and `Plugins:` labels, `(none)`, `Opened a new chat window.` and `unknown tool <name>`. These strings are read by a model or an MCP client, and the source passes none of them through a localization table. A port MUST reproduce them verbatim, since callers may match on them.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `Returns the host app's name, version and loaded plugins.` | `host_app_info` description |
| (none; literal) | `Opens a new AI chat window in the host app.` | `host_open_chat_window` description |
| (none; literal) | `Host: / Version: / Plugins:` | Labels in the `host_app_info` result |
| (none; literal) | `(none)` | Plugin list when empty |
| (none; literal) | `Opened a new chat window.` | `host_open_chat_window` result |
| (none; literal) | `unknown tool <name>` | Error result for an unrecognised tool |

## Accessibility Options

Not applicable: the component has no visual output, motion or colour, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag or setting; whether the source is registered is decided by the caller.

## Analytics

Not applicable: the source records no events.

## Privacy

- **Data collected**: None. The component holds the app name, app version and plugin names it was given and returns them on request.
- **Storage**: None; the values live in memory for the life of the instance.
- **Transmission**: The values leave the process only when the registering server sends the result of `host_app_info` to a connected MCP client or chat engine; this class itself performs no transmission.
- **Retention**: Not applicable: nothing is persisted.

## Logging

Not applicable: the source makes no log call. The registering `HostMCPServer` logs the tool name and outcome of each call.

## Platform Notes

- **SwiftUI**: Source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/HostAppToolSource.swift` in the macOS module, with `ChatToolSource`, `ToolDefinition` and `ToolJSONSchema` from the Core module. There is no view. A SwiftUI app passes a closure that opens a window through its scene machinery (for example the `openWindow` environment action captured by the app delegate) as `openChatWindow`.
- **Compose**: Write a Kotlin class implementing the host's tool interface, with `suspend fun callTool(name, argumentsJson, caller)` returning a pair of content and an error flag. Inject `openChatWindow` as a `suspend () -> Unit` that switches to the main dispatcher (`withContext(Dispatchers.Main)`) to match the main-actor callback. Build the empty schema as a `JsonObject` with `type` set to `object` and an empty `properties`.
- **React/Web**: Write a TypeScript class with `toolDefinitions()` returning two plain objects with a JSON Schema and `async callTool(name, argsJson, caller)` returning an object with `content` and `isError`. Build the info text with an array joined by a line feed and `plugins.join(", ")`. Inject `openChatWindow` as an async function; a browser has no main-actor rule, so the isolation requirement has no equivalent.
- **AppKit / UIKit**: Same source file; it uses only `Foundation`. The callback is where AppKit enters: the host passes a closure that creates an `NSWindowController` for the chat window. UIKit has no multi-window default, so on iOS the callback would request a new scene session with `UIApplication.shared.requestSceneSessionActivation`.
- **WinUI 3**: Implement as a plain .NET class implementing the host's tool interface, with `async Task<(string Content, bool IsError)> CallToolAsync(string name, ReadOnlyMemory<byte> argumentsJson, string? caller)`. Take `Func<Task>` for the callback and run it on the UI thread through `DispatcherQueue.TryEnqueue` with a `TaskCompletionSource`, so the call completes after the window is created, matching the `@MainActor` await. Build the info text with `string.Join(", ", pluginNames)` and `string.Join("\n", ...)`; use `"\n"`, not `Environment.NewLine`, to match the source. Keep the fields `readonly` for the same immutability. Create the window with `new Window()` and `Activate()` inside the callback; the tool source itself uses no XAML and no `INotifyPropertyChanged`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/HostAppToolSource.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The open-chat-window action is an injected callback, not a direct call into the app's window code.
**Rationale**: The source lives in the macOS feature module but the window-creation code belongs to the host app; a closure keeps the tool source free of app types and testable with a counter, as `HostAppToolSourceTests` does.
**Approved**: pending

**Decision**: `host_open_chat_window` reports success unconditionally.
**Rationale**: The callback returns nothing and cannot throw, so the source has no signal to report a failure. This is the actual behaviour; a port that wants failure reporting changes the callback's type and this contract together.
**Approved**: pending

**Decision**: Both tools are one source with bare names; the host server owns any prefix and the routing.
**Rationale**: The source comment describes it as what the server "used to hard-code, now one source among several", so naming and routing moved to `HostMCPServer`, and this class stays a plain list of two tools.
**Approved**: pending

**Decision**: Arguments and the caller identifier are ignored.
**Rationale**: Neither tool takes parameters or picks a target by proximity, so there is nothing to validate; the unused `caller` is part of the `ChatToolSource` signature, not of this source's needs.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The class separates the tool contract from the app's window code through the injected callback. `HostAppToolSourceTests` covers the tool list, both results, the callback count and the empty-plugin case, but not the unknown-tool path, so coverage is partial. Errors are returned as values, never thrown. The result and description strings are hardcoded English literals, so the no-hardcoded-strings check fails; the strings are protocol payload for a model, not user interface text, which the Localization section records.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
