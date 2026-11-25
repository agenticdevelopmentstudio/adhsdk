---
id: 86788f50-7b85-4659-b7df-8c560e082f76
title: "Agent Tool"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-25
modified: 2026-11-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The JSON-in, JSON-out tool contract a host offers its agents, its call and result types, and a client that loads a remote host's tools and runs each one over a handler transport."
platforms:
  - swift
  - macos
tags:
  - agents
  - tools
  - json-schema
  - mcp
depends-on: []
related:
  - dac3e46e-2eeb-4ebd-b88d-4e4999870db7
references: []
approved-by: ""
approved-date: ""
---

# Agent Tool

## Overview

An agent tool is one capability a host offers its agents and, through the MCP bridge, other clients: a function that takes a JSON object of arguments and returns a JSON result, described by a name, a description and a JSON Schema. This ingredient covers the contract in `AgentTool.swift` (the `AgentTool` protocol, `ToolPermission`, `ToolCallContext`, `ToolInvocation`, `ToolOutcome`, `AgentToolError`) and `RemoteAgentTools.swift`, a client that loads the tools of a host in another process over the host's handlers (`GET tools`, `POST tools/<name>`) and wraps each one as a local `AgentTool` whose `run` executes remotely. The transport (HTTP to a daemon, XPC, or an in-process handler set for tests) is supplied by the caller. The host side (`AgentHandlers`, `AgentHost`, `AgentToolSource`, and the MCP bridge, described in [Host MCP Server](cookbook:dac3e46e-2eeb-4ebd-b88d-4e4999870db7)) is outside this ingredient; this ingredient states what the client sends and expects from it.

## Behavioral Requirements

### The tool contract

- **tool-identity**: An `AgentTool` MUST expose `name` and `description` as strings.
- **tool-schema**: An `AgentTool` MUST expose `inputSchemaJSON`, the JSON Schema of its arguments, as a JSON string.
- **tool-reason-convention**: An `AgentTool` that is mutating SHOULD require a `reason` string in its schema; the host records it in its activity entry. This is a documented convention on implementers: neither the protocol nor `RemoteAgentTool` validates it.
- **tool-permission-default**: An `AgentTool` MUST expose `permissionDefault` as a `ToolPermission`.
- **tool-permission-values**: `ToolPermission` MUST have exactly three cases with the raw string values `auto`, `ask` and `never`, and MUST be `Codable` and `Sendable`.
- **tool-permission-enforcement**: Nothing in this ingredient blocks a run on the basis of `ToolPermission`: `run` MUST execute regardless of `permissionDefault`, and a conforming tool MUST NOT assume the type stops a call.
- **tool-mutating-flag**: An `AgentTool` MUST expose `isMutating`, which states whether running it changes state.
- **tool-mutating-report**: A mutating tool's run is reported by the host as an `ActivityEntry` and returns its undo as `ToolOutcome.inverse`; an implementation of a mutating tool SHOULD return an `inverse`.
- **tool-run**: An `AgentTool` MUST implement `run(argumentsJSON:context:)` as `async throws`, taking the arguments as a JSON string and a `ToolCallContext`, and returning a `ToolOutcome`.
- **tool-sendable**: `AgentTool` MUST refine `Sendable` so a tool can be shared across concurrent turns.

### Data shapes

- **context-shape**: `ToolCallContext` MUST carry `caller` (a string such as `agent`, `external` or a CLI name), an optional `agentId` and an optional `sessionId` (a `UUID`), and MUST be `Sendable` and `Equatable`.
- **context-defaults**: `ToolCallContext.init(caller:agentId:sessionId:)` MUST default `agentId` and `sessionId` to nil.
- **invocation-shape**: `ToolInvocation` MUST carry `tool` (the tool name) and `argumentsJSON` (a JSON string), and MUST be `Codable`, `Sendable` and `Equatable`.
- **outcome-shape**: `ToolOutcome` MUST carry `resultJSON` (what the model sees), `summary` (one human line, for narration) and an optional `inverse` (a `ToolInvocation`), and MUST be `Codable`, `Sendable` and `Equatable`.
- **outcome-inverse-default**: `ToolOutcome.init(resultJSON:summary:inverse:)` MUST default `inverse` to nil.
- **inverse-persistence**: `ToolOutcome.inverse` MUST be a `Codable` value, and the code in this ingredient MUST NOT store or replay it; a caller that wants undo MUST persist and run it itself.

### Errors

- **tool-error-cases**: `AgentToolError` MUST have two cases, `unknownTool(String)` and `invalidArguments(tool:)`, each meaning a call could not be run at all, as distinct from a tool that ran and threw. `invalidArguments(tool:)` MUST describe itself as `The arguments for '<tool>' are not a JSON object`.
- **tool-error-unknown-message**: `AgentToolError.unknownTool(name)` MUST describe itself as `Unknown tool '<name>'`.
- **tool-throw-passthrough**: A tool that runs and fails MUST signal it by throwing from `run`; the contract defines no result-level error field on `ToolOutcome`.

### Remote client: RemoteAgentTools

- **remote-init**: `RemoteAgentTools` MUST be created with a `caller` string, defaulting to `AgentHandlers.defaultToolCaller` (the string `external`), and a `Transport`, an `@Sendable` async throwing closure from `HandlerRequest` to `HandlerResponse`.
- **remote-transport-paths**: The transport MUST receive paths relative to the host's agent mount, for example the single segment `tools`.
- **remote-load-request**: `load()` MUST send one `GET` with path `["tools"]`.
- **remote-load-order**: `load()` MUST return the tools in the order the host listed them.
- **remote-load-fields**: For each element of the reply array, `load()` MUST read `name`, `description`, `input_schema`, `permission` and `mutating`.
- **remote-name-required**: `load()` MUST throw `RemoteAgentToolError.malformedReply("A tool has no name")` when an element's `name` is missing, not a string, or empty.
- **remote-description-default**: `load()` MUST use an empty string when `description` is missing or not a string.
- **remote-schema-encoding**: `load()` MUST re-encode `input_schema` as JSON with sorted keys into `inputSchemaJSON`, and MUST use an empty object when `input_schema` is missing.
- **remote-schema-fallback**: `load()` MUST use `{}` for `inputSchemaJSON` if the re-encoded bytes are not valid UTF-8.
- **remote-permission-default**: `load()` MUST map `permission` through `ToolPermission(rawValue:)` and MUST fall back to `auto` when it is missing or not one of `auto`, `ask`, `never`.
- **remote-mutating-default**: `load()` MUST use `false` for `isMutating` when `mutating` is missing or not a boolean.
- **remote-array-required**: `load()` MUST throw `RemoteAgentToolError.malformedReply("Expected a JSON array of tools")` when the 2xx reply body is JSON but not an array of objects, and MUST throw the same error, rather than skip the element, when the array mixes objects with other values.
- **remote-run-request**: A loaded tool's `run` MUST send one `POST` with path `["tools", <name>]` and a JSON body of `{"arguments": <object>, "caller": <caller>}`.
- **remote-caller-replaced**: A loaded tool's `run` MUST send the `RemoteAgentTools` caller and MUST ignore `context.caller`, `context.agentId` and `context.sessionId`, "since the host sees this process as one caller".
- **remote-cancellation**: `run` MUST NOT check for task cancellation itself, before or after it sends the request; cancellation is honoured only if the transport throws, and that error MUST propagate unchanged (`remote-transport-errors`).
- **remote-arguments-parse**: A loaded tool's `run` MUST parse `argumentsJSON` into a JSON object and send it as `arguments`.
- **remote-arguments-fallback**: A loaded tool's `run` MUST send `{}` as `arguments` when `argumentsJSON` is empty or only whitespace, and MUST throw `AgentToolError.invalidArguments(tool:)` without sending anything when it is anything else that is not a JSON object (invalid JSON, an array, a string or a number).
- **remote-run-result**: A loaded tool's `run` MUST decode a 2xx reply body as a `ToolOutcome` and return it, including `inverse` when present.
- **remote-reply-must-be-json**: Both `load()` and `run` MUST throw `RemoteAgentToolError.malformedReply("Expected JSON, got an event stream")` when the transport answers with an event stream rather than a JSON reply.
- **remote-status-failure**: Both `load()` and `run` MUST throw `RemoteAgentToolError.failed(status:message:)` for a JSON reply whose status is outside 200 to 299, with `message` taken from the decoded `HandlerError` body's `message`, else the body as UTF-8 text, else an empty string.
- **remote-status-meaning**: A `failed` status of 404 means the host does not know the tool and 422 means the tool ran and threw (as the host's handler defines them); this code passes both through unchanged, with no retry.
- **remote-error-description**: `RemoteAgentToolError.failed` and `.malformedReply` MUST both use their message string as `errorDescription`.
- **remote-transport-errors**: An error thrown by the transport MUST propagate out of `load()` and `run` unchanged.
- **remote-concurrency**: `RemoteAgentTools` and `RemoteAgentTool` MUST be `Sendable` structs holding no mutable state, and MUST NOT take a lock or serialise calls, so concurrent `load()` or `run` calls are independent transport calls.

## Appearance

Not applicable — this is a tool contract and a transport client, not a visual component.

## States

Not applicable — this is a tool contract and a transport client, not a visual component. `RemoteAgentTools` and the loaded tools hold only immutable configuration (the caller and the transport) and have no runtime state machine.

## Accessibility

Not applicable — this is a tool contract and a transport client, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-tool-001 | remote-load-request, remote-load-order, remote-load-fields, remote-permission-default, remote-mutating-default, remote-schema-encoding | `RemoteAgentTools(caller: "mcp")` over the in-process handlers of a host holding `echo`, `bump`, `broken`; `load()` (test `loads`), capturing the requests | The one request is `GET` with path `["tools"]`; names are `["echo", "bump", "broken"]`; `bump.isMutating` is true, `bump.permissionDefault` is `ask`, and its `inputSchemaJSON` parses to an object whose `required` is `["reason"]` |
| agent-tool-002 | remote-run-request, remote-caller-replaced, remote-arguments-parse, remote-run-result | Loaded with caller `bridge`; `echo.run(argumentsJSON: {"text":"x"}, context: ToolCallContext(caller: "ignored"))` (test `runs`) | `resultJSON` contains `"caller":"bridge"` and `"text":"x"`; `summary` is `Echoed`; the one request is `POST` with path `["tools", "echo"]` and a body that decodes to `{"arguments": {"text": "x"}, "caller": "bridge"}` |
| agent-tool-003 | remote-status-failure, remote-status-meaning, remote-error-description | `broken.run(argumentsJSON: "{}", ...)` against a host whose tool throws "The tool broke" (test `failure`) | Throws `RemoteAgentToolError.failed(status: 422, message: "The tool broke")` |
| agent-tool-004 | remote-status-failure, remote-transport-paths | Transport answers every request with an error reply of status 500, message `Down`; `load()` (test `listFails`), capturing the request | The request is `GET` with path `["tools"]`; throws `RemoteAgentToolError.failed(status: 500, message: "Down")` |
| agent-tool-005 | remote-array-required | Transport answers 200 with body `{}`; `load()` (test `malformed`) | Throws `RemoteAgentToolError.malformedReply("Expected a JSON array of tools")` |
| agent-tool-006 | remote-name-required | Transport answers 200 with `[{"description":"x"}]`; `load()` | Throws `malformedReply("A tool has no name")` |
| agent-tool-007 | remote-name-required | Transport answers 200 with `[{"name":""}]`; `load()` | Throws `malformedReply("A tool has no name")` |
| agent-tool-008 | remote-permission-default, remote-mutating-default, remote-description-default, remote-schema-encoding | Transport answers 200 with `[{"name":"t","permission":"bogus"}]`; `load()` | One tool: `permissionDefault` is `auto`, `isMutating` is false, `description` is empty, `inputSchemaJSON` is `{}` |
| agent-tool-009 | remote-reply-must-be-json | Transport answers with an event-stream reply; `load()` | Throws `malformedReply("Expected JSON, got an event stream")` |
| agent-tool-010 | remote-status-failure | Transport answers status 500 with a body that is not a `HandlerError`, the text `boom`; `echo.run(argumentsJSON: "{}", ...)` | Throws `failed(status: 500, message: "boom")` |
| agent-tool-011 | tool-error-unknown-message, tool-error-cases | `AgentToolError.unknownTool("nope").errorDescription` | `Unknown tool 'nope'` |
| agent-tool-012 | tool-permission-values | `ToolPermission(rawValue:)` for `auto`, `ask`, `never`, and `maybe` | `.auto`, `.ask`, `.never`, nil |
| agent-tool-013 | context-defaults, outcome-inverse-default | `ToolCallContext(caller: "cli")` and `ToolOutcome(resultJSON: "{}", summary: "s")` | `agentId` and `sessionId` are nil; `inverse` is nil |
| agent-tool-014 | remote-error-description | `RemoteAgentToolError.malformedReply("m").errorDescription` and `.failed(status: 404, message: "n").errorDescription` | `m` and `n` |
| agent-tool-015 | remote-run-result, outcome-shape | Host reply to a mutating tool is `{"resultJSON":"{\"count\":1}","summary":"Bumped the counter","inverse":{"tool":"unbump","argumentsJSON":"{}"}}`; `bump.run` | Returned `ToolOutcome.inverse` equals `ToolInvocation(tool: "unbump", argumentsJSON: "{}")` |
| agent-tool-016 | remote-arguments-fallback | `echo.run(argumentsJSON:)` with `not json`, `[1, 2]` and `"text"`, then with `  ` (test `malformedArguments`) | The first three throw `AgentToolError.invalidArguments(tool: "echo")` and post nothing; the last posts `{}` and returns the tool's outcome |
| agent-tool-017 | remote-array-required | Transport answers 200 with `[{"name":"a"}, 5]`; `load()` | Throws `malformedReply("Expected a JSON array of tools")` |
| agent-tool-018 | tool-error-cases | `AgentToolError.invalidArguments(tool: "echo").errorDescription` | `The arguments for 'echo' are not a JSON object` |

Vectors agent-tool-001 to agent-tool-005 and agent-tool-016 cite existing tests; agent-tool-006 to agent-tool-015, agent-tool-017 and agent-tool-018 derive from the source rather than from an existing test; the SHOULD requirements `tool-reason-convention` and `tool-mutating-report` have no vector because the convention is placed on host implementers and is not checked by this code (the fixture `CounterTool` in the test support file follows it).
## Edge Cases

- **Empty tool list**: A reply of `[]` yields an empty array from `load()` (MUST); no error is thrown.
- **Missing schema**: A tool with no `input_schema` yields `{}` (MUST).
- **Unknown permission string**: Yields `auto`, the most permissive value, with no error (MUST, as written in `remote-permission-default`; a known hazard, see Design Decisions).
- **Invalid argument JSON**: `run` throws `invalidArguments` and posts nothing; empty arguments are posted as `{}` (`remote-arguments-fallback`).
- **Arguments that are valid JSON but not an object** (an array, string or number): `run` throws `invalidArguments(tool:)` and posts nothing (`remote-arguments-fallback`).
- **List reply array mixing objects and other values**: `load()` throws `malformedReply("Expected a JSON array of tools")`; it does not skip the other elements (MUST, `remote-array-required`).
- **Non-JSON 200 body from the list**: `JSONSerialization` throws its own error, not a `RemoteAgentToolError`; that error propagates (MUST).
- **Non-2xx with an undecodable body**: The message falls back to the body's UTF-8 text, then to an empty string (MUST).
- **Unknown tool name at call time**: The host answers 404 and the client throws `failed(status: 404, ...)`; the client does not refresh its tool list (MUST).
- **Transport unreachable or cancelled**: The transport's error propagates out, and `run` makes no cancellation check of its own (`remote-cancellation`); there is no timeout, retry, backoff or reconnection in this code, and the owner of those is the transport the caller supplies (MUST propagate, SHOULD be handled by the caller).
- **Tool list changes after load**: A loaded tool is a snapshot; changes on the host are seen only by calling `load()` again (MUST NOT be assumed live).
- **Duplicate tool names in a reply**: Both entries are returned in order; this code does not deduplicate.
- **Concurrent calls**: Not serialised; the code is stateless, and any ordering rule belongs to the host.
- **Offline**: Not applicable beyond the transport error above; the client keeps no cache and has no offline mode.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `caller` | `String` | `AgentHandlers.defaultToolCaller` (`external`) | The caller name every remote run reports to the host |
| `transport` | `@Sendable (HandlerRequest) async throws -> HandlerResponse` | none (required) | Delivers requests to the host's agent mount: HTTP, XPC, or an in-process `AgentHandlers` |
| `ToolCallContext.caller` | `String` | none (required) | The caller of a local run; ignored by remote tools |
| `ToolCallContext.agentId` | `String?` | nil | The agent running the tool, from an agent's turn |
| `ToolCallContext.sessionId` | `UUID?` | nil | The session of the turn |

## Deep Linking

Not applicable: neither file registers or handles a URL; the `tools` paths are handler-mount paths, not links.

## Localization

`AgentToolError.unknownTool`, `AgentToolError.invalidArguments` and the `malformedReply` messages ("Expected a JSON array of tools", "A tool has no name", "Expected JSON, got an event stream") are hardcoded English strings with no localization lookup; a `failed` message is whatever the host sent.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `Unknown tool '<name>'` | `AgentToolError.unknownTool` description |
| none (hardcoded) | `The arguments for '<tool>' are not a JSON object` | `AgentToolError.invalidArguments` description |
| none (hardcoded) | `Expected a JSON array of tools` | `load()` reply not an array |
| none (hardcoded) | `A tool has no name` | `load()` element without a name |
| none (hardcoded) | `Expected JSON, got an event stream` | Reply was an event stream |

## Accessibility Options

Not applicable: this is a non-visual contract and client with no motion, contrast or color behavior.

## Feature Flags

Not applicable: neither file reads a feature flag or setting.

## Analytics

Not applicable: neither file emits an analytics event.

## Privacy

Tool arguments and results are sent by this code, with no encryption of its own, to whatever transport the caller supplies; the files add no credential, token or persistent storage. The doc comments state that a mutating tool's `reason` is recorded by the host in its activity entry, which is host behavior outside these files.

- **Data collected**: None by this code; the arguments and results it relays may contain user data.
- **Storage**: None; `ToolOutcome.inverse` is data only and these files do not persist it.
- **Transmission**: To the host over the caller's transport; the host's transport owns confidentiality and authentication.
- **Retention**: None in these files.

## Logging

Not applicable: neither file makes a logging call; failures are thrown, not logged.

## Platform Notes

- **SwiftUI**: Not a view. The Swift source uses `Foundation` only: `JSONSerialization` for the schema and argument bodies, `Codable` for `ToolOutcome` and `ToolInvocation` (decoded through the module's `AgentsJSON`), and `async`/`await` with `Sendable` closures. A SwiftUI app consumes the loaded `[any AgentTool]` through its own model; nothing here is view-specific.
- **Compose**: Start from a Kotlin `interface AgentTool` with a `suspend fun run`, `kotlinx.serialization` data classes for the three shapes, and an `enum class ToolPermission` with serial names `auto`, `ask`, `never`. Use `Ktor` or `OkHttp` as the transport and map non-2xx replies to a sealed `RemoteAgentToolError`; the Swift `throws` becomes a thrown exception or a `Result`. Kotlin has no `Equatable`, so data classes provide equality.
- **React/Web**: Use a TypeScript interface for the tool with `run(argumentsJSON: string, context): Promise<ToolOutcome>`, string-literal unions for `ToolPermission`, and `fetch` as the transport (`GET tools`, `POST tools/<name>` with a JSON body). Differences: `JSON.parse` failure must be handled explicitly to reproduce the empty-object fallback, and object key order is not sorted unless you sort it when re-encoding the schema.
- **AppKit / UIKit**: The code is not UI, so there is nothing to build in AppKit or UIKit; on macOS the transport is typically `URLSession` to the daemon's loopback HTTP, or `NSXPCConnection`; the in-process `AgentHandlers` transport is used in tests.
- **WinUI 3**: Define `interface IAgentTool` with `Task<ToolOutcome> RunAsync(string argumentsJson, ToolCallContext context, CancellationToken ct)`, `ToolPermission` as an enum serialised as lowercase strings (`JsonStringEnumConverter` with a `JsonNamingPolicy.CamelCase`), and the three shapes as `record` types with `System.Text.Json` (`JsonSerializer`) in place of `Codable`. Implement the remote client as a class holding an `HttpClient` (or a `Func<HandlerRequest, Task<HandlerResponse>>` to match the Swift transport seam), parse the list with `JsonDocument` and sort schema keys when re-serialising to match `.sortedKeys`. Throw a `RemoteAgentToolException` with `Status` and `Message` properties for non-2xx replies. Since `ToolPermission` is not enforced here, a WinUI host that shows a permission prompt would bind a `ComboBox` to the enum through `INotifyPropertyChanged` outside this component. In an ASP.NET Core host the equivalents of the handlers are two minimal API routes, `MapGet("tools")` and `MapPost("tools/{name}")`, returning 404 for an unknown tool and 422 for a thrown one.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Agent/AgentTool.swift` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/MCP/RemoteAgentTools.swift` | unverified |

## Design Decisions
**Decision**: A mutating tool declares itself with `isMutating` and returns its undo as data (`ToolOutcome.inverse`) rather than a closure.
**Rationale**: An undo has to outlive the call that made it and cross a process boundary in the reply body, so it must be a `Codable` value; a closure can be neither stored nor sent. The context of the original call is dropped because the inverse names a tool and its arguments, which is all a replay needs. No artifact owns persisting or replaying it yet.
**Approved**: pending

**Decision**: `ToolPermission` is stored per agent but this ingredient does not enforce it.
**Rationale**: The type exists first so agent definitions can carry the setting; enforcing it needs the host's run path, which is outside this ingredient. No artifact owns enforcement yet, so until one does, nothing blocks a run on `ask` or `never`.
**Approved**: pending

**Decision**: `AgentToolError` covers only a call that could not be run (an unknown tool, or arguments that are not a JSON object); a tool that runs and fails throws its own error.
**Rationale**: The host maps the first kind to 404 and the second to 422, so a caller can tell a bad call from a failed tool. Argument refusal is client-side and sends nothing.
**Approved**: pending

**Decision**: A remote tool ignores the `ToolCallContext` and sends the `RemoteAgentTools` caller.
**Rationale**: The host sees this process as one caller, and the transport has no field for per-agent identity, so sending the context would claim an identity the host cannot verify.
**Approved**: pending

**Decision**: The transport is injected as a closure rather than a fixed HTTP client.
**Rationale**: The same client has to run over HTTP to a daemon, over XPC and over an in-process `AgentHandlers` in tests; a closure from request to response is the narrowest seam all three fit.
**Approved**: pending

**Decision**: A missing `mutating` falls back to false, and an unknown or missing `permission` falls back to `auto`, the most permissive value, with no error.
**Rationale**: The fallbacks keep `load()` working against a host that omits a field. The `auto` fallback is a known hazard, not a feature: it fails open, and it is safe today only because nothing here enforces permissions. A port may choose `ask` instead; changing the code is pending approval.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | failed | reliability |

The contract types, the error type and the remote client are separate, and the transport and the host are injected or out of scope, so separation of concerns passes. Unit tests (the `RemoteAgentTools` suite) cover load, run, failure replies and a malformed list, but not a missing name, defaults for omitted fields, the event-stream reply, or the `AgentToolError` and `ToolPermission` types directly, so coverage is partial. Errors are thrown with typed cases and the host's message, and invalid argument JSON is refused with `invalidArguments` rather than sent (`remote-arguments-fallback`), but a missing or unknown `permission` is silently mapped to `auto` instead of being surfaced, so error handling is partial. The client sets no timeout and leaves it entirely to the transport, so timeout handling is failed.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-25 | Mike Fullerton | Initial creation |
