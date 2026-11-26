---
id: dac3e46e-2eeb-4ebd-b88d-4e4999870db7
title: "HostMCPServer"
type: ingredient
version: 1.3.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One MCP server for the host app: advertises every registered tool source under tools/list and routes tools/call to the owner, over any transport; AgentToolSource bridges AgentTools."
platforms:
  - swift
  - macos
  - ios
tags:
  - mcp
  - server
  - tool-source
  - routing
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
  - 2affdc87-3c3b-4f7d-819d-f54ba947f2f1
references: []
approved-by: ""
approved-date: ""
---

# HostMCPServer

## Overview

`HostMCPServer` is an actor that turns a set of `ChatToolSource` values into one Model Context Protocol server. Every registered source is advertised under `tools/list`, and `tools/call` is routed to the source that advertises the requested name. The source comment calls it "transport-agnostic": the in-app chat and the HTTP endpoint hand it different transports, and the actor serves whichever it is given.

The actor owns three things: a list of registrations (a source and a name prefix), the current SDK `Server` for the live connection, and the translation between the tool-source contract (name, JSON argument bytes, optional caller, a content string and an error flag) and MCP's result type. It also reads the caller's pane identifier from the `X-ADHD-Pane` request header, or the older `X-ADKitchen-Pane`. Starting, stopping and the draining variant used for standard input live here and in `HostMCPServer+Stdio`.

`AgentToolSource` is the bridge from agent tools to this server. It is a `ChatToolSource` that wraps a list of `AgentTool` values (name, description, JSON schema string, and a `run` that takes JSON text and a `ToolCallContext`), so registering it exposes those tools to any MCP client and to a chat engine's tool loop. The source's doc comment shows the intended use: register it with no prefix, loading the tools from `RemoteAgentTools`, then serve over standard input.

Source: `HostMCPServer` is `packages/apple/AgenticDeveloperHubSDK/Core/MCP/HostMCPServer.swift` in the Core module (Foundation, the MCP Swift SDK and OSLog, no view code). `AgentToolSource` is `packages/apple/AgenticDeveloperHubSDK/Agents/MCP/AgentToolSource.swift` in the Agents module, which also holds the `AgentTool` protocol. The two types share one ingredient because the bridge is a small adapter to the server's `ChatToolSource` contract; the pending Design Decision on the bridge records why they are not split.
## Behavioral Requirements

Construction and registration

- **construction-parameters**: The server MUST be constructed from an app name and an app version, and MUST advertise them as its MCP server name and version.
- **register-appends**: `register(_:prefix:)` MUST append the source to the registration list; registration order is the order sources are listed and the order they are searched on a call.
- **prefix-default**: When no prefix is given, the registration MUST use the empty prefix.
- **registrations-survive-stop**: Registrations MUST survive `stop()`, so a later `serve(over:)` serves the same tools; callers MUST NOT re-register.
- **caller-header-name**: The server MUST expose the header name `X-ADHD-Pane` as `callerHeader`, the old name `X-ADKitchen-Pane` as `legacyCallerHeader`, and both, in that order, as `callerHeaders`.

Serving

- **fresh-server-per-serve**: Each `serve(over:)` MUST create a new SDK `Server`, because the SDK marks a server initialized on its first `initialize` and never clears that, so a reused server would answer the next client's `initialize` with "Server is already initialized".
- **serve-stops-previous**: If a server is already serving, `serve(over:)` MUST stop it before starting the new one, so the old connection and receive task are cancelled.
- **serve-serialized**: `serve(over:)` and `stop()` MUST run one at a time, in the order they were called: a call MUST NOT begin until every earlier `serve(over:)` or `stop()` has finished, including across the suspension points inside each call. So of two overlapping `serve(over:)` calls the later one stops the earlier one's server and its own server is the one left serving (last call wins), and a `stop()` called while a `serve(over:)` is starting stops the server that call starts. A `serve(over:)` that throws does not block the calls queued after it.
- **tools-capability**: The server MUST declare the tools capability with `listChanged` false.
- **not-strict**: The server MUST be created with the SDK's default configuration, not strict mode, so a stateless HTTP caller can send `tools/call` without a prior `initialize`.
- **serve-throws-start-failure**: `serve(over:)` MUST throw when starting the SDK server on the transport throws, and in that case MUST NOT record the new server as current.
- **stop-clears-server**: `stop()` MUST stop the current SDK server and clear it; calling it with no server MUST do nothing.
- **wait-until-completed**: The server MUST be able to report when the current connection's message loop ends, by waiting on the SDK server; with no server it MUST return at once.

Listing

- **list-concatenates**: `tools/list` MUST return the definitions of every registration, in registration order and in each source's own order.
- **list-prefix**: Each advertised name MUST be the registration's prefix followed by the definition's name.
- **list-description**: Each advertised tool MUST carry the definition's description unchanged.
- **list-schema**: Each advertised tool's input schema MUST be the definition's parameters JSON schema decoded as an MCP value.
- **list-schema-fallback**: When a definition's schema bytes do not decode, the tool MUST still be advertised with the schema `{"type": "object", "properties": {}}`.
- **list-asks-sources-live**: `tools/list` MUST ask each source for its definitions on every request; the server MUST NOT cache them.
- **list-duplicates-kept**: If two registrations advertise the same full name, `tools/list` MUST list both; the server does not deduplicate.
- **list-server-gone**: If the server has been deallocated when a list request arrives, the handler MUST return an empty tool list.

Calling

- **call-routing**: `tools/call` MUST be sent to the first registration, in order, whose prefix the requested name starts with and whose source advertises the name once the prefix is removed.
- **call-prefix-stripped**: The source MUST receive the name with the registration's prefix removed.
- **call-arguments-json**: The source MUST receive the call's arguments encoded as a JSON object; absent arguments MUST be sent as an empty object.
- **call-arguments-fallback**: If the arguments cannot be encoded, the source MUST receive the bytes of `{}`.
- **call-asks-definitions**: Before dispatching, the server MUST ask the candidate source for its current definitions to confirm it advertises the bare name.
- **call-caller**: The source MUST receive the value of the first of `callerHeaders` the request carries (`X-ADHD-Pane`, then `X-ADKitchen-Pane`) as the caller, or nil when there is no HTTP request or neither header.
- **caller-header-case**: The header lookup MUST be case-insensitive, as the request type's header accessor is; the test sets the lowercase `x-adkitchen-pane`.
- **call-result-text**: A result whose content does not start with the PNG data-URL prefix MUST become one text content item carrying the content unchanged.
- **call-result-error-flag**: The MCP result's `isError` MUST equal the source's error flag.
- **call-result-image**: A result whose content starts with `data:image/png;base64,` MUST become one image content item with the text after the prefix as its data and the MIME type `image/png`.
- **call-image-error-flag**: A PNG data-URL result MUST still carry the source's error flag.
- **call-unknown-tool**: When no registration matches, the server MUST return an error result with the text `unknown tool <name>`, as a normal result and not a protocol error.
- **call-server-gone**: If the server has been deallocated when a call arrives, the handler MUST return an error result with the text `server is gone`.
- **call-first-match-only**: Once a registration matches, the server MUST NOT try later registrations, even when the first source's result is an error.

Agent tool bridge (`AgentToolSource`)

- **bridge-definitions**: `AgentToolSource.toolDefinitions()` MUST return one definition per tool in its `tools` list, in list order, with the tool's `name` and `description` and the UTF-8 bytes of its `inputSchemaJSON` as the parameters schema.
- **bridge-caller-default**: `AgentToolSource` MUST take its `caller` from the initializer, and when none is given it MUST use `AgentHandlers.defaultToolCaller`, the string `external`.
- **bridge-caller-fixed**: `callTool` MUST run the tool with a `ToolCallContext` whose `caller` is the source's own `caller`, and MUST NOT pass on the caller the MCP request supplied; the context's `agentId` and `sessionId` MUST be nil.
- **bridge-result**: When the tool returns, `callTool` MUST answer the outcome's `resultJSON` with the error flag false; the outcome's `summary` and `inverse` MUST NOT be part of the answer.
- **bridge-arguments**: `callTool` MUST hand the tool the argument bytes decoded as UTF-8 text, and MUST hand it `{}` when the bytes are empty.
- **bridge-arguments-undecodable**: When non-empty argument bytes are not valid UTF-8, `callTool` MUST hand the tool an empty string.
- **bridge-unknown-tool**: When no tool in the list has the requested name, `callTool` MUST answer the text `Unknown tool '<name>'` with the error flag true and MUST NOT run any tool.
- **bridge-name-first-match**: When two tools share a name, `callTool` MUST run the first in list order.
- **bridge-failure**: When the tool throws, `callTool` MUST answer the error's `localizedDescription` with the error flag true.
- **bridge-ignores-policy**: `callTool` MUST NOT read the tool's `permissionDefault` or `isMutating`, and MUST NOT record an activity entry; it runs every listed tool.

Logging

- **call-log**: Every call MUST write one info log line `tools/call <name> ok`, `tools/call <name> error` or `tools/call <name> unknown`, with the name and outcome logged as public.

## Appearance

Not applicable — this is a protocol server, not a visual component.

## States

Not applicable — this is a protocol server, not a visual component. Its runtime states are described under Behavioral Requirements: idle (no current server), serving (a current server over a transport), and back to idle after `stop()` or after the message loop ends and `stop()` is called.

## Accessibility

Not applicable — this is a protocol server, not a visual component.

## Conformance Test Vectors

Derived from `HostMCPServerTests` where named; the rest are traced to the source. "Pair" means a server and client joined by an in-memory transport.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| host-mcp-server-001 | list-concatenates | Sources with names a, b and c; `tools/list` (`testListToolsConcatenatesSourcesInRegistrationOrder`) | Names `a`, `b`, `c`; first description `echo a` |
| host-mcp-server-002 | list-schema, list-description | One source whose schema has a string property `x`; `tools/list` (`testInputSchemaIsTheDefinitionsSchema`) | Schema type is `object` and `properties` contains `x` |
| host-mcp-server-003 | call-routing, call-arguments-json, call-first-match-only | Two sources (`a`, `b`); call `b` with `x` set to `1` (`testCallRoutesToTheSourceThatAdvertisesTheName`) | Text `echo:b`, no error; second source received arguments `{"x":"1"}`; first source received no call |
| host-mcp-server-004 | call-result-error-flag, call-result-text | Source whose tool `fails` returns `it failed` with error true (`testErrorResultIsErrorWithTheSentence`) | `isError` true, text `it failed` |
| host-mcp-server-005 | call-unknown-tool | Call `nope` with no matching source (`testUnknownToolIsAnErrorResultNotAProtocolError`) | Result `isError` true, text `unknown tool nope`, no protocol error |
| host-mcp-server-006 | list-prefix, call-prefix-stripped | Source `info` registered with prefix `host_`; list, then call `host_info` (`testPrefixIsAppliedToNamesAndStrippedOnCall`) | Listed name `host_info`; source received name `info` |
| host-mcp-server-007 | call-result-image | Source returns `data:image/png;base64,iVBORw0KGgo=` (`testPNGDataURLBecomesImageContent`) | One image item, MIME `image/png`, data `iVBORw0KGgo=` |
| host-mcp-server-008 | serve-stops-previous, fresh-server-per-serve | Serve over a first pair and connect, then serve over a second pair and connect a new client (`testSecondServeStopsTheFirst`) | The second client initializes without error and lists `a` |
| host-mcp-server-009 | call-caller, caller-header-case | Request with header `x-adkitchen-pane: pane-7`; read caller, call the server with it (`testCallerHeaderReachesTheSource`) | Caller `pane-7`; the source records caller `pane-7` |
| host-mcp-server-010 | call-caller | No request, or a request with no header | Caller is nil |
| host-mcp-server-011 | caller-header-name | Read `HostMCPServer.callerHeader`, `legacyCallerHeader` and `callerHeaders` | `X-ADHD-Pane`; `X-ADKitchen-Pane`; both, the new name first |
| host-mcp-server-012 | list-schema-fallback | Source whose definition's schema bytes are not JSON; `tools/list` | The tool is listed with schema type `object` and empty properties |
| host-mcp-server-013 | call-arguments-json | Call with no arguments | Source receives `{}` |
| host-mcp-server-014 | call-image-error-flag | Source returns the PNG data URL with the error flag true | Image content with `isError` true |
| host-mcp-server-015 | list-duplicates-kept | Two sources both advertising `a`; `tools/list` | Two entries named `a`; a call goes to the first source |
| host-mcp-server-016 | registrations-survive-stop | Register a source, serve, stop, serve again over a new transport | The second connection lists the same tools without re-registering |
| host-mcp-server-017 | stop-clears-server | Call `stop()` on a server that never served | Returns with no effect and no error |
| host-mcp-server-018 | tools-capability, not-strict | A client calls `tools/call` over a stateless transport with no prior `initialize`; a second client connects normally and reads the `initialize` result | The call is answered, not refused; the initialize result's tools capability is present and its `listChanged` is false |
| host-mcp-server-019 | register-appends, prefix-default | Register two sources with no prefix | Both are listed in the order registered |
| host-mcp-server-020 | construction-parameters | Construct with app name `Test` and version `1`, connect a client | The client's initialize result names server `Test` version `1` |
| host-mcp-server-021 | serve-throws-start-failure | Transport whose connect throws | `serve(over:)` throws and a following `stop()` does nothing |
| host-mcp-server-022 | call-log | One successful, one failing and one unknown call | Info lines `tools/call a ok`, `tools/call fails error`, `tools/call nope unknown` |
| host-mcp-server-023 | list-asks-sources-live, call-asks-definitions | Source whose definitions change between two `tools/list` requests | The second listing reflects the change |
| host-mcp-server-024 | call-result-text | Source returns `hello` | One text item `hello`, no image |
| host-mcp-server-025 | list-server-gone, call-server-gone, wait-until-completed | Server deallocated before a request; and `waitUntilServerCompleted()` with no server | Empty list and `server is gone`; the wait returns at once. `HostMCPServerConformanceTests` reaches both: it drops the server after serving, then lists and calls, and it waits on a server that never served. |
| host-mcp-server-026 | bridge-definitions | `AgentToolSource` over `EchoTool` and `FailingTool`; `toolDefinitions()` (`AgentToolSourceTests.definitions`) | Names `echo`, `broken`; first definition's schema bytes equal the UTF-8 bytes of `EchoTool`'s `inputSchemaJSON` |
| host-mcp-server-027 | bridge-result, bridge-caller-fixed, bridge-arguments | Source with caller `mcp`; call `echo` with `{"text":"x"}` and request caller `other` (`AgentToolSourceTests.callSucceeds`) | Not an error; content contains `"caller":"mcp"` |
| host-mcp-server-028 | bridge-arguments | Same source; call `echo` with empty argument bytes and request caller nil (`AgentToolSourceTests.callSucceeds`) | Content contains `"echo":{}` |
| host-mcp-server-029 | bridge-unknown-tool | Call `nope` (`AgentToolSourceTests.callFails`) | `isError` true; text `Unknown tool 'nope'` |
| host-mcp-server-030 | bridge-failure | Call `broken`, whose run throws a failure with message `The tool broke` (`AgentToolSourceTests.callFails`) | `isError` true; content `The tool broke` |
| host-mcp-server-031 | bridge-caller-default (`AgentToolSourceTests.defaultCaller`) | `AgentToolSource(tools:)` with no caller; read `caller` | `external` |
| host-mcp-server-032 | bridge-arguments-undecodable (`AgentToolSourceTests.undecodableArguments`) | Call `echo` with argument bytes that are not valid UTF-8 | The tool receives an empty string as its arguments |
| host-mcp-server-033 | bridge-name-first-match (`AgentToolSourceTests.firstNameMatch`) | Two tools named `echo` in one source; call `echo` | The first tool runs |
| host-mcp-server-034 | bridge-result, bridge-ignores-policy (`AgentToolSourceTests.mutatingToolRuns`) | Call a mutating `ask` tool through an `AgentToolSource`, as `HostMCPServer` does for `tools/call` | The tool runs and its `resultJSON` is the content; no activity entry is written by the bridge |
| host-mcp-server-035 | call-first-match-only | Two sources both advertising `b`; the first returns an error (`it failed`, error true), the second would return `echo:b`; call `b` | `isError` true, text `it failed`; the second source received no call |
| host-mcp-server-036 | serve-serialized, serve-stops-previous (`HostMCPServerTests.testOverlappingServesRunInCallOrder`) | Start `serve(over: A)` on a transport whose `connect()` waits for a release; while it waits, start `serve(over: B)`; then release A | B's `connect()` is not called until A's `serve` returns; then A is disconnected and B connected, and B's server is the one serving |
| host-mcp-server-037 | serve-serialized, serve-throws-start-failure (`HostMCPServerTests.testFailedServeDoesNotBlockTheQueue`) | `serve(over:)` a transport whose `connect()` throws, then `serve(over:)` an in-memory pair | The first throws; the second serves and a client lists the tools |
## Edge Cases

- **No registrations**: `tools/list` MUST return an empty list, and any `tools/call` MUST return `unknown tool <name>`.
- **Source with no tools**: MUST contribute nothing to the listing and never match a call.
- **Empty or missing arguments**: MUST be sent to the source as `{}`.
- **Tool name equal to a prefix**: a name that equals a registration's prefix leaves an empty bare name, which matches only a source that advertises an empty name; otherwise the next registration is tried.
- **Empty prefix and overlapping prefixes**: the empty prefix matches every name, so registration order decides; earlier registrations win.
- **Name advertised by two sources**: the first registered source is called; the second is unreachable by that name.
- **Source throws or returns an error**: sources return a content string and an error flag and cannot throw through the contract; an error flag becomes an MCP error result, and no later registration is tried.
- **Schema bytes that do not decode**: MUST fall back to an empty object schema; the failure is not logged.
- **Concurrent calls**: the actor serialises its own state, but `tools/call` handlers run in separate tasks in the SDK and each awaits the source, so two calls to a slow source can overlap; the server adds no lock around source calls.
- **Overlapping `serve` or `stop`**: `serve(over:)` and `stop()` suspend (on `stop()`, `installHandlers`, `start`), and an actor lets another call in at each suspension. They are therefore queued: each waits for every earlier call to finish before it reads the current server, so overlapping calls take effect in call order and the last one wins (`serve-serialized`).
- **Transport closes**: the message loop ends and `waitUntilServerCompleted()` returns; the server stays recorded as current until `stop()` is called.
- **Stateless HTTP caller**: a `tools/call` with no `initialize` MUST be answered.
- **Unreachable client or network loss mid-call**: the source call continues to completion and the reply is written to the transport; the server has no retry, timeout or cancellation of its own.
- **Agent tool list empty**: an `AgentToolSource` with no tools MUST contribute no definitions and answer every call with `Unknown tool '<name>'`.
- **Mutating or ask-permission tool through the bridge**: the bridge runs it without consulting `permissionDefault` or `isMutating` and returns its `resultJSON`; `ToolPermission`'s doc comment says it is "enforced in phase 2", so the bridge's silence on policy is the current contract, not a hidden check. The tool's inverse is dropped.
- **Pane header versus bridge caller**: the pane id the server reads from the request reaches `callTool`, and `AgentToolSource` discards it for its own fixed caller; a tool that wants the pane cannot see it through this bridge.
- **Argument bytes that are not UTF-8**: the tool receives an empty string and decides for itself whether that is valid; the bridge raises no error.
- **Tool throws any error**: the error's `localizedDescription` becomes the answer text with the error flag true; nothing is rethrown.
- **Caller header absent**: the caller MUST be nil, and sources that ignore it are unaffected.

## Configuration
| Owner | Option | Type | Default | Description |
|-------|--------|------|---------|-------------|
| HostMCPServer | `appName` | String | none (required) | The MCP server name sent in the `initialize` result |
| HostMCPServer | `appVersion` | String | none (required) | The MCP server version sent in the `initialize` result |
| HostMCPServer | `source` | `ChatToolSource` | none | A tool source added with `register(_:prefix:)` |
| HostMCPServer | `prefix` | String, optional | empty | Put before every tool name the source advertises; removed before a call reaches it |
| HostMCPServer | `transport` | `Transport` | none (required) | The MCP transport passed to `serve(over:)` |
| HostMCPServer | `callerHeader` | static String | `X-ADHD-Pane` | Request header naming the calling pane |
| HostMCPServer | `legacyCallerHeader` | static String | `X-ADKitchen-Pane` | The header's name before adhd served the tools; still read |
| HostMCPServer | `callerHeaders` | static [String] | `[callerHeader, legacyCallerHeader]` | Every name the caller is read from, in order |
| AgentToolSource | `tools` | `[any AgentTool]` | none (required) | The agent tools an `AgentToolSource` serves |
| AgentToolSource | `caller` | String | `AgentHandlers.defaultToolCaller` (`external`) | The caller every bridged tool sees in its `ToolCallContext` |
## Deep Linking

Not applicable: the server routes MCP method calls and defines no URL scheme or route; the HTTP route belongs to the endpoint that supplies the transport.

## Localization

The server returns hardcoded English in two places: `unknown tool <name>` and `server is gone`. They are protocol payload read by an MCP client or model, not interface text, and the source passes them through no localization table. Tool descriptions and results come from the sources and are not altered.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `unknown tool <name>` | Error result when no registration matches |
| (none; literal) | `server is gone` | Error result when the server was deallocated before the call |

## Accessibility Options

Not applicable: the component has no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag or setting; which sources are registered is the caller's choice.

## Analytics

Not applicable: the source emits no analytics events; the only record of a call is the log line under Logging.

## Privacy

- **Data collected**: None stored. Tool names are logged. Tool arguments and results pass through to sources and clients and are not logged.
- **Storage**: None; registrations and the current server live in memory.
- **Transmission**: Results leave the process over whichever transport the caller supplies. The caller identifier is read from a request header and passed to the source; it is a pane id, not a user identity.
- **Retention**: Not applicable: nothing is persisted.

## Logging

Subsystem: `AgenticDeveloperHubSDK` | Category: `automation`

| Event | Level | Message |
|-------|-------|---------|
| Call routed and answered without an error flag | info | `tools/call <name> ok` |
| Call routed and answered with an error flag | info | `tools/call <name> error` |
| No registration matched | info | `tools/call <name> unknown` |

The tool name and outcome are logged with public privacy. The stdio drain adds a warning, described in the [host-mcp-server-stdio ingredient](cookbook:2affdc87-3c3b-4f7d-819d-f54ba947f2f1); its `HostMCPServer+Stdio` extension is part of that ingredient.

## Platform Notes

- **SwiftUI**: A SwiftUI app owns one `HostMCPServer` instance for the life of the process, for example in its app-level model object, so the HTTP endpoint and any in-app chat share the same registrations. Register sources once at launch, before the first `serve(over:)`; registrations survive `stop()`. Call `stop()` when the app tears down the transport it served over (for example when the endpoint is switched off in settings) and at app termination so the receive task is cancelled. The actor needs no main-thread access, so views read nothing from it directly.
- **Compose**: Write a Kotlin class around the MCP Kotlin SDK server, with a `Mutex`-guarded list of registrations and a `suspend` handler for list and call. Use a sealed class for the content (text or image) and decode a `data:image/png;base64,` prefix with `startsWith`. A Kotlin SDK server may be reusable across connections; the fresh-server-per-connect rule exists because of this Swift SDK's behaviour and should be kept only if the SDK has the same flaw.
- **React/Web**: Write a TypeScript class using `@modelcontextprotocol/sdk`'s `Server` with `setRequestHandler` for the list-tools and call-tool schemas. JavaScript is single-threaded, so the registration array needs no lock. Read the caller from the incoming request headers (`extra.requestInfo.headers`, lower-cased by Node).
- **AppKit / UIKit**: Nothing in the Core file touches AppKit or UIKit, so the same instance model applies on macOS and iOS. On macOS the app delegate, or the object that owns the HTTP endpoint (`MCPHTTPEndpoint`), holds the instance and starts or stops it with the endpoint. On iOS, hold it in the scene-independent app model and call `stop()` when the transport cannot survive suspension, then `serve(over:)` again on return to the foreground.
- **WinUI 3**: Implement as a plain .NET class using the official C# MCP SDK (`ModelContextProtocol` NuGet package) with `McpServer` and `McpServerTool` handlers, or `WithListToolsHandler` and `WithCallToolHandler` to route by prefix. Hold registrations in a `List<Registration>` guarded by `SemaphoreSlim` in place of the Swift actor, and expose `RegisterAsync` and `ServeAsync(ITransport)` as `Task`. Return image results with `ImageContentBlock` and text with `TextContentBlock`. For the HTTP case, expose the same service through an ASP.NET Core minimal API route (`app.MapPost("/mcp", ...)`) and read the `X-ADHD-Pane` value, or failing that `X-ADKitchen-Pane`, from `HttpRequest.Headers`, which is case-insensitive. Log with `ILogger<HostMCPServer>` at `LogLevel.Information`. For the agent tool bridge, define an `IAgentTool` interface and a source that implements the same list-and-call contract: it maps each tool to a definition with its schema string, runs the first tool whose name matches with a fixed caller, and turns a thrown exception into its `Message` with the error flag set. No XAML, `ObservableCollection` or `INotifyPropertyChanged` is involved; if a host UI lists the tools it reads the list from the service on demand.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/MCP/HostMCPServer.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/MCP/AgentToolSource.swift` | unverified |

## Design Decisions

**Decision**: A new SDK `Server` is created for each `serve(over:)`.
**Rationale**: The source comment explains that the SDK marks a `Server` initialized on its first `initialize` and never clears it, not even in `stop()`, so reuse answers the next client with "Server is already initialized".
**Approved**: pending

**Decision**: An existing connection is stopped before a new one starts.
**Rationale**: The source comment notes that the SDK's `Server.start` would overwrite the connection and receive task without cancelling the old ones.
**Approved**: pending

**Decision**: The server is not created in strict mode.
**Rationale**: A stateless HTTP caller sends `tools/call` with no `initialize` first, and strict mode would refuse it (source comment).
**Approved**: pending

**Decision**: Unknown tools, a missing server and source errors are returned as error results, not protocol errors.
**Rationale**: The model sees the sentence and can recover; `testUnknownToolIsAnErrorResultNotAProtocolError` asserts it for unknown names.
**Approved**: pending

**Decision**: Routing asks each candidate source for its definitions on every call instead of keeping a name table.
**Rationale**: Sources may change what they advertise (the `tools/list` capability sets `listChanged` false, so the server never announces the change, and a client reads the new list only by asking again). The cost is one definition fetch per call; the source does not say why a cache was not used.
**Approved**: pending

**Decision**: A PNG data URL becomes image content.
**Rationale**: The source comment says the tool set renders screenshots as a data URL so a text-only chat still gets something, and this is where MCP gets the real image.
**Approved**: pending

**Decision**: Registrations survive `stop()`.
**Rationale**: The same server is served over several transports in turn (stop then serve), and the source comment forbids re-registering.
**Approved**: pending

**Decision**: `AgentToolSource` runs every tool with its own fixed caller and ignores the pane id the MCP request names.
**Rationale**: The source comment says "The MCP caller id is not passed on: a tool sees `caller`." `AgentToolSourceTests.callSucceeds` asserts the fixed caller wins over the request's.
**Approved**: pending

**Decision**: The bridge does not enforce `permissionDefault` or record activity for mutating tools.
**Rationale**: `ToolPermission`'s doc comment says permissions are "Stored per agent now; enforced in phase 2", and `AgentTool` says a mutating tool's run is reported as an activity entry by the host; the bridge contains neither step.
**Approved**: pending

**Decision**: `AgentToolSource` stays inside this ingredient and is not split into its own.
**Rationale**: It is a small adapter that exists only to feed `HostMCPServer`'s `ChatToolSource` contract, so the two are versioned together. The cost is that an Agents-module type shares a recipe with a Core-module type, which is why the Configuration table has an Owner column. Splitting it into an ingredient that lists this one in `depends-on` is the alternative if the bridge grows or gains other consumers.
**Approved**: pending

**Decision**: The bridge runs mutating and ask-permission tools for any MCP client, including stateless HTTP callers, with no permission check and no activity record. This is an accepted risk for now.
**Rationale**: Permissions are stored per agent but not enforced until phase 2 (`ToolPermission`'s doc comment), and the transport owner limits who can reach the server. Removal trigger: the bridge MUST gain a permission check and an activity record before any non-loopback transport, any transport without authentication, or any untrusted MCP client is allowed to reach it, and in any case when phase 2 permission enforcement ships.
**Approved**: pending

**Decision**: There is no per-call timeout on a source call, and no option to set one.
**Rationale**: This is deliberate debt. The transport owner or the stdio drain deadline bounds a hung source today, and a per-call timeout needs a cancellation contract that `ChatToolSource` does not have. The debt is paid when `ChatToolSource.callTool` gains cancellation, at which point a timeout option MUST be added to `HostMCPServer`.
**Approved**: pending

**Decision**: The `Logger` is a private instance with no injection point, so the call log (vector host-mcp-server-022) has no test.
**Rationale**: The source constructs its own OSLog `Logger`. Injecting a logger or log sink through the initializer would make vector 022 assertable and is the intended direction; until then the lines are specified here and verified by reading the source.
**Approved**: pending

**Decision**: `serve(over:)` and `stop()` are serialised through one queue, in call order, and the last call wins.
**Rationale**: Actor isolation alone does not order them: each suspends after reading the current server, so a second call could start a server the first then overwrote without stopping, leaking a connection and its receive task. Refusing a second `serve` would break the existing `serve-stops-previous` contract, where a host re-serves over a new transport on reconnect; queueing keeps that contract and makes it hold under overlap. Each call is a task that awaits the one before it, so a thrown `serve` releases the queue (`serve-serialized`).
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | security |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | failed | security |

Separation of concerns is partial because `AgentToolSource` shares this ingredient (see its Design Decision). Server-side authorization fails for the bridge: it runs mutating and ask-permission tools with no permission check, an accepted risk with a removal trigger recorded in Design Decisions. The server keeps routing, the MCP translation and transport choice separate: transports and tool sources arrive from outside. `AgentToolSourceTests` cover vectors 026 to 034. `HostMCPServerTests` and `HostMCPServerConformanceTests` cover every server vector except host-mcp-server-022 (the call log lines), which is skipped because the `Logger` is a private OSLog instance with no injection point; overlapping serve calls are an unspecified edge case with a pending Design Decision. Coverage is therefore partial. Failures come back as error results. Logs carry tool names and outcomes only, not arguments or results. The server sets no timeout on a source call, so a hung source holds its request open; the transport owner or the stdio drain deadline bounds it.

## Change History

| Version | Date | Author | Summary |
| 1.3.0 | 2026-11-25 | Mike Fullerton | serve(over:) and stop() are queued in call order (serve-serialized); the last call wins and a thrown serve does not block the queue. |
|---------|------|--------|---------|
| 1.2.0 | 2026-11-25 | Mike Fullerton | Added the AgentToolSource bridge: exposes AgentTools to the host MCP server with a fixed caller; header text corrected to X-ADHD-Pane. |
| 1.1.0 | 2026-11-23 | Mike Fullerton | Apps suite Phase 4: callerHeader is X-ADHD-Pane; legacyCallerHeader and callerHeaders added. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (HostMCPServerConformanceTests.swift, 14 new vectors; 24 of 25 covered with HostMCPServerTests); unit-test-coverage now partial (host-mcp-server-022 skipped: Logger not capturable). |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
