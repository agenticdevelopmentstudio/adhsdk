---
id: dac3e46e-2eeb-4ebd-b88d-4e4999870db7
title: "HostMCPServer"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One MCP server for the host app: advertises every registered tool source under tools/list and routes tools/call to the source that owns the name, over any transport."
platforms:
  - swift
  - macos
tags:
  - mcp
  - server
  - tool-source
  - routing
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# HostMCPServer

## Overview

`HostMCPServer` is an actor that turns a set of `ChatToolSource` values into one Model Context Protocol server. Every registered source is advertised under `tools/list`, and `tools/call` is routed to the source that advertises the requested name. The source comment calls it "transport-agnostic": the in-app chat and the HTTP endpoint hand it different transports, and the actor serves whichever it is given.

The actor owns three things: a list of registrations (a source and a name prefix), the current SDK `Server` for the live connection, and the translation between the tool-source contract (name, JSON argument bytes, optional caller, a content string and an error flag) and MCP's result type. It also reads the caller's pane identifier from the `X-ADKitchen-Pane` request header. Starting, stopping and the draining variant used for standard input live here and in `HostMCPServer+Stdio`.

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
- **tools-capability**: The server MUST declare the tools capability with `listChanged` false.
- **not-strict**: The server MUST be created with the SDK's default configuration, not strict mode, so a stateless HTTP caller can send `tools/call` without a prior `initialize`.
- **serve-throws-start-failure**: `serve(over:)` MUST throw when starting the SDK server on the transport throws, and in that case MUST NOT record the new server as current.
- **stop-clears-server**: `stop()` MUST stop the current SDK server and clear it; calling it with no server MUST do nothing.
- **wait-until-completed**: The server MUST be able to report when the current connection's message loop ends, by waiting on the SDK server; with no server it MUST return at once.
- **serve-reentrancy**: NEEDS REVIEW: Not implemented in source. `serve(over:)` and `stop()` are actor methods that suspend (on `stop()`, `installHandlers`, `start`) after reading `server`, and the source gives no ordering rule for two overlapping calls, so one call can replace or clear the connection another has just recorded; a test that issues two `serve(over:)` calls without awaiting the first would settle the intended behaviour.

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
| host-mcp-server-018 | tools-capability, not-strict | A client calls `tools/call` over a stateless transport with no prior `initialize` | The call is answered, not refused |
| host-mcp-server-019 | register-appends, prefix-default | Register two sources with no prefix | Both are listed in the order registered |
| host-mcp-server-020 | construction-parameters | Construct with app name `Test` and version `1`, connect a client | The client's initialize result names server `Test` version `1` |
| host-mcp-server-021 | serve-throws-start-failure | Transport whose connect throws | `serve(over:)` throws and a following `stop()` does nothing |
| host-mcp-server-022 | call-log | One successful, one failing and one unknown call | Info lines `tools/call a ok`, `tools/call fails error`, `tools/call nope unknown` |
| host-mcp-server-023 | list-asks-sources-live, call-asks-definitions | Source whose definitions change between two `tools/list` requests | The second listing reflects the change |
| host-mcp-server-024 | call-result-text | Source returns `hello` | One text item `hello`, no image |
| host-mcp-server-025 | list-server-gone, call-server-gone, wait-until-completed | Server deallocated before a request; and `waitUntilServerCompleted()` with no server | Empty list and `server is gone`; the wait returns at once. `HostMCPServerConformanceTests` reaches both: it drops the server after serving, then lists and calls, and it waits on a server that never served. |

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
- **Overlapping `serve` or `stop`**: see the open question on `serve-reentrancy`.
- **Transport closes**: the message loop ends and `waitUntilServerCompleted()` returns; the server stays recorded as current until `stop()` is called.
- **Stateless HTTP caller**: a `tools/call` with no `initialize` MUST be answered.
- **Unreachable client or network loss mid-call**: the source call continues to completion and the reply is written to the transport; the server has no retry, timeout or cancellation of its own.
- **Caller header absent**: the caller MUST be nil, and sources that ignore it are unaffected.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `appName` | String | none (required) | The MCP server name sent in the `initialize` result |
| `appVersion` | String | none (required) | The MCP server version sent in the `initialize` result |
| `source` | `ChatToolSource` | none | A tool source added with `register(_:prefix:)` |
| `prefix` | String, optional | empty | Put before every tool name the source advertises; removed before a call reaches it |
| `transport` | `Transport` | none (required) | The MCP transport passed to `serve(over:)` |
| `callerHeader` | static String | `X-ADHD-Pane` | Request header naming the calling pane |
| `legacyCallerHeader` | static String | `X-ADKitchen-Pane` | The header's name before adhd served the tools; still read |
| `callerHeaders` | static [String] | `[callerHeader, legacyCallerHeader]` | Every name the caller is read from, in order |

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

The tool name and outcome are logged with public privacy. The stdio drain adds a warning, described in the `host-mcp-server-stdio` recipe.

## Platform Notes

- **SwiftUI**: Source is `packages/apple/AgenticDeveloperHubSDK/Core/MCP/HostMCPServer.swift` in the Core module (Foundation, the MCP Swift SDK and OSLog), with no view code. A SwiftUI app owns one instance, registers its sources at launch and hands it a transport; the actor needs no main-thread access.
- **Compose**: Write a Kotlin class around the MCP Kotlin SDK server, with a `Mutex`-guarded list of registrations and a `suspend` handler for list and call. Use a sealed class for the content (text or image) and decode a `data:image/png;base64,` prefix with `startsWith`. A Kotlin SDK server may be reusable across connections; the fresh-server-per-connect rule exists because of this Swift SDK's behaviour and should be kept only if the SDK has the same flaw.
- **React/Web**: Write a TypeScript class using `@modelcontextprotocol/sdk`'s `Server` with `setRequestHandler` for the list-tools and call-tool schemas. JavaScript is single-threaded, so the registration array needs no lock. Read the caller from the incoming request headers (`extra.requestInfo.headers`, lower-cased by Node).
- **AppKit / UIKit**: Same file; nothing in it touches AppKit or UIKit, so it builds for every Apple platform the Core module supports. The in-app chat and the HTTP endpoint (`MCPHTTPEndpoint`, macOS module) are the two callers that supply transports.
- **WinUI 3**: Implement as a plain .NET class using the official C# MCP SDK (`ModelContextProtocol` NuGet package) with `McpServer` and `McpServerTool` handlers, or `WithListToolsHandler` and `WithCallToolHandler` to route by prefix. Hold registrations in a `List<Registration>` guarded by `SemaphoreSlim` in place of the Swift actor, and expose `RegisterAsync` and `ServeAsync(ITransport)` as `Task`. Return image results with `ImageContentBlock` and text with `TextContentBlock`. For the HTTP case, expose the same service through an ASP.NET Core minimal API route (`app.MapPost("/mcp", ...)`) and read the `X-ADKitchen-Pane` value from `HttpRequest.Headers`, which is case-insensitive. Log with `ILogger<HostMCPServer>` at `LogLevel.Information`. No XAML, `ObservableCollection` or `INotifyPropertyChanged` is involved; if a host UI lists the tools it reads the list from the service on demand.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/MCP/HostMCPServer.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | security |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |

The server keeps routing, the MCP translation and transport choice separate: transports and tool sources arrive from outside. `HostMCPServerTests` and `HostMCPServerConformanceTests` cover every vector except host-mcp-server-022 (the call log lines), which is skipped because the `Logger` is a private OSLog instance with no injection point; overlapping serve calls remain an open question in the requirements. Coverage is therefore partial. Failures come back as error results. Logs carry tool names and outcomes only, not arguments or results. The server sets no timeout on a source call, so a hung source holds its request open; the transport owner or the stdio drain deadline bounds it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-23 | Mike Fullerton | Apps suite Phase 4: callerHeader is X-ADHD-Pane; legacyCallerHeader and callerHeaders added. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (HostMCPServerConformanceTests.swift, 14 new vectors; 24 of 25 covered with HostMCPServerTests); unit-test-coverage now partial (host-mcp-server-022 skipped: Logger not capturable). |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
