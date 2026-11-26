---
id: f9f7ae23-0da9-41fb-a065-968a028d059e
title: "Agent Handlers"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-25
modified: 2026-11-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Server-independent HTTP route tables for the agent host and the model registry: request and response types, JSON dialect, status mapping, tool-call bridge."
platforms:
  - swift
  - macos
tags:
  - ai
  - agents
  - http-handlers
  - engine
depends-on:
  - d711486e-1195-417b-9baf-7315354dae8d
  - 12d36a57-8d7d-454e-a2ee-44effbd9e93b
  - 86788f50-7b85-4659-b7df-8c560e082f76
related: []
references: []
approved-by: ""
approved-date: ""
---

# Agent Handlers

## Overview

Agent Handlers is the HTTP-shaped front door to the agent framework, written so that no server is involved. A hosting process (the example host, roosterd, mounts the agent routes at `/agent` and the model routes at `/models`; any mount point works) converts each incoming request into a `HandlerRequest` (method, path segments below the mount, query dictionary, body bytes), calls `handle` on a handler set, and relays the returned `HandlerResponse`: either a status with a JSON body, or a stream of `AgentEnvelope` values that the server forwards, for the example host as server-sent events with the event `type` as the event name.

The component is four cooperating pieces:

- `HandlerRequest`, `HandlerResponse` and `HandlerError`: the transport-neutral request, the two-case reply, and the `{"error":"<code>","message":"..."}` error body shared by every handler.
- `AgentHandlers`: the agent host's routes (agents, sessions, messages, interrupt, event tail, tools list and tool call).
- `ModelHandlers`: the model registry's routes (entries, test, model list, plugins, role resolution).
- `AgentsJSON`: the single JSON dialect (ISO-8601 dates, sorted keys, unescaped slashes) used for every stored row, body and fixture.

The agent host (`AgentHost`, [Agent Host](cookbook:d711486e-1195-417b-9baf-7315354dae8d)), the model registry (`ModelRegistry`, [Model Registry](cookbook:12d36a57-8d7d-454e-a2ee-44effbd9e93b)) and the tool protocol (`AgentTool`, `ToolOutcome`, `ToolCallContext`, [Agent Tool](cookbook:86788f50-7b85-4659-b7df-8c560e082f76)) have their own ingredients. This ingredient specifies how requests map onto them and how their errors map onto statuses.

The source is Swift in `AgenticDeveloperHubSDK`: `Agents/Handlers/HandlerRequest.swift`, `AgentHandlers.swift`, `ModelHandlers.swift` and `Agents/Support/AgentsJSON.swift`, with `Sendable` handler structs over an actor host, an `async` `handle`, `AsyncStream` for events and `JSONSerialization` for the routes that need loose objects. There is no view code.

Boundary: the handlers only route, map and serialise. They do not authenticate, authorise, gate on a tool's permission, validate an agent beyond the id check, log, or touch files, the network or processes; each of those belongs to the mounting server, the host or the registry.

## Behavioral Requirements

### Request and response types

- **request-method-uppercase**: `HandlerRequest` MUST upper-case the method it is given, so a lowercase `get` is stored as `GET`.
- **request-path-segments**: The string-path initializer of `HandlerRequest` MUST split the path on `/`, drop empty segments (leading, trailing and doubled slashes), and percent-decode each segment; a segment that cannot be percent-decoded MUST be kept as written.
- **request-segments-pure**: `HandlerRequest.segments` MUST be a public pure function of the path string, so a server can reuse the same splitting.
- **request-defaults**: `HandlerRequest` MUST default `query` to an empty dictionary and `body` to empty data.
- **request-json-object**: The body helper `jsonObject` MUST return an empty dictionary for an empty body, the parsed dictionary for a JSON object, and nil for anything else (malformed JSON, or a JSON array, string or number at the top level).
- **response-cases**: `HandlerResponse` MUST have exactly two cases: `json(status:body:)` and `events(AsyncStream<AgentEnvelope>)`.
- **response-status**: `HandlerResponse.status` MUST return the carried status for a JSON reply and 200 for an event stream.
- **response-error-shape**: `HandlerResponse.error(status, code, message)` MUST produce a JSON reply whose body decodes to a `HandlerError` holding that code and message.
- **response-error-codes**: The error codes MUST be `bad_request` (status 400), `not_found` (404), `conflict` (409), `unprocessable` (422) and `internal` (500).
- **response-encoded**: `HandlerResponse.encoded(value, status:)` MUST encode the value with `AgentsJSON` and default the status to 200.
- **response-encoded-failure**: When `encoded` cannot encode its value it MUST answer 500 with code `internal` and the encoder's localized description.
- **response-empty**: `HandlerResponse.empty(status)` MUST be a JSON reply with a zero-length body.
- **no-route-shape**: The shared no-route reply MUST be 404 with code `not_found` and message `No such route`.

### JSON dialect

- **json-dates**: `AgentsJSON` MUST encode and decode dates as ISO-8601.
- **json-encoder-format**: `AgentsJSON` MUST encode with sorted keys and without escaping forward slashes.
- **json-fresh-coders**: `AgentsJSON.encoder()` and `AgentsJSON.decoder()` MUST return a new coder on every call, because the underlying coder types are not `Sendable`.
- **json-string-forms**: `AgentsJSON` MUST offer `encodeString` (UTF-8 text, or an empty string if the bytes are not valid UTF-8) and a `decode` overload that takes a string.

### Dispatch and error mapping (shared by both handler sets)

- **handle-never-throws**: `handle` on `AgentHandlers` and on `ModelHandlers` MUST NOT throw; every failure MUST be returned as a JSON error reply.
- **handle-async**: `handle` MUST be asynchronous and the handler structs MUST be `Sendable` values holding only their host or registry.
- **decoding-error-400**: A `DecodingError` raised while routing MUST answer 400 `bad_request` with the message `Malformed body: ` followed by a description.
- **decoding-error-description**: Both handler sets MUST describe a `DecodingError` with the one shared `HandlerError.describe(_:)`, which lives beside `HandlerError` so neither set depends on the other. The description MUST be ``missing `<key>` `` for a missing key, and otherwise the dotted coding path in backticks, a colon and the decoder's debug description (or the debug description alone when the path is empty).
- **unexpected-error-500**: Any error that is neither the owning component's error type nor a `DecodingError` MUST answer 500 `internal` with the error's localized description.
- **uuid-case-insensitive**: A path id that is a UUID string MUST be parsed whatever its letter case, on both the session routes and the model entry routes.
- **segment-before-decode**: The `HandlerRequest` string initializer MUST split the path on `/` before percent-decoding, so an encoded slash (`%2F`) stays inside its segment and an encoded space is part of one segment.
- **method-case**: Route matching MUST compare against the upper-cased method held by `HandlerRequest`.

### Agent routes: dispatch

- **route-top-level**: `AgentHandlers` MUST dispatch on the first path segment: `agents`, `sessions` or `tools`; any other first segment, or an empty path, MUST answer the no-route reply.
- **route-method-fallthrough**: Within a recognised top-level segment, a method or segment count that no case matches MUST answer the no-route reply (for example `PATCH agents`).
- **default-tool-caller**: `AgentHandlers.defaultToolCaller` MUST be the string `external`.

### Agent routes: agents

- **agents-list**: `GET agents` MUST answer 200 with the host's agent definitions as a JSON array.
- **agents-get**: `GET agents/<id>` MUST answer 200 with the definition, or 404 `not_found` with the message `No agent with id '<id>'` when the host has none.
- **agents-put-object**: `PUT agents/<id>` MUST answer 400 `Expected a JSON object` when the body is not a JSON object.
- **agents-put-id-mismatch**: `PUT agents/<id>` MUST answer 400 when the body carries a string `id` different from the path id, with a message naming both.
- **agents-put-id-from-path**: `PUT agents/<id>` MUST set the saved definition's `id` to the path id, whether or not the body carried one.
- **agents-put-decode**: `PUT agents/<id>` MUST decode the body as an `AgentDefinition` with `AgentsJSON`; a body missing a required field MUST answer 400 through the decoding-error mapping.
- **agents-put-save**: `PUT agents/<id>` MUST call the host's `save` and, on success, answer 200 with the definition it saved; a host `invalidAgent` error MUST answer 400.
- **agents-empty-id-not-checked**: The handler MUST NOT validate the id beyond the mismatch check; an invalid agent is refused by the host.

### Agent routes: sessions

- **sessions-list**: `GET sessions` MUST answer 200 with the host's sessions, filtered by the `agent` query parameter when it is present.
- **sessions-create**: `POST sessions` with body `{agent, title?}` MUST create a session and answer 201 with its `AgentSessionInfo`.
- **sessions-create-agent-missing**: `POST sessions` naming an agent the host does not know MUST answer 404 `not_found`; session creation does not check whether the agent is enabled, so a disabled agent is refused with 409 `conflict` only when a message is sent to the session.
- **sessions-collection-methods**: On `sessions` with one path segment, a method other than `GET` or `POST` MUST answer the no-route reply.
- **sessions-id-parse**: A second path segment that is not a UUID string MUST answer 404 `not_found` with the message `No session with id '<segment>'`, for every method and sub-path.
- **sessions-get**: `GET sessions/<id>` MUST answer 200 with the `AgentSessionDetail`, or 404 when the session does not exist.
- **sessions-delete**: `DELETE sessions/<id>` MUST delete the session and answer 204 with an empty body; a second delete of the same id MUST answer 404.
- **sessions-sub-path**: Any `sessions/<id>/<other>` path beyond the ones named here, or a known sub-path with the wrong method, MUST answer the no-route reply.
- **empty-body-defaults**: For `PUT agents/<id>` and `POST tools/<name>` an empty body MUST be treated as the empty object; for `POST sessions` and `POST sessions/<id>/messages` an empty body MUST fail decoding and answer 400.
- **malformed-json-body**: Where a route decodes with `AgentsJSON`, malformed JSON MUST answer 400 `Malformed body: ...`; where it uses `jsonObject`, malformed JSON MUST answer 400 `Expected a JSON object`.
- **sessions-extra-segments**: The handler MUST read only the third segment to choose a sub-route; segments after the third are ignored.

### Agent routes: messages, events, interrupt

- **messages-decode**: `POST sessions/<id>/messages` MUST decode `{text}`; a body without `text` MUST answer 400 through the decoding-error mapping.
- **messages-empty**: `POST sessions/<id>/messages` MUST answer 400 `The message text is empty` when `text` is empty or only whitespace and newlines, without calling the host.
- **messages-stream**: `POST sessions/<id>/messages` MUST answer with the `events` stream returned by the host's `send`, carrying the turn's envelopes.
- **messages-busy**: `POST sessions/<id>/messages` MUST answer 409 `conflict` when the host reports a turn already in progress.
- **messages-host-errors**: `POST sessions/<id>/messages` MUST map host errors through the shared map (see #requirements/host-error-map).
- **events-tail**: `GET sessions/<id>/events` MUST answer with the host's live event stream for the session, or 404 when the session does not exist.
- **interrupt**: `POST sessions/<id>/interrupt` MUST call the host's `interrupt` and answer 202 with an empty body, or 404 when the session does not exist.
- **host-error-map**: Host errors MUST map as: `agentNotFound` and `sessionNotFound` to 404 `not_found`; `agentDisabled` and `turnInProgress` to 409 `conflict`; `invalidAgent` to 400 `bad_request`. The message MUST be the error's localized description.

### Agent routes: tools

- **tools-list**: `GET tools` MUST answer 200 with a JSON array, in the host's tool order, of objects holding `name`, `description`, `input_schema`, `permission` and `mutating`.
- **tools-list-schema**: In the tool list, `input_schema` MUST be the tool's `inputSchemaJSON` parsed into a JSON value, and MUST be an empty object when that text is not valid JSON.
- **tools-list-permission**: In the tool list, `permission` MUST be the raw value of the tool's `permissionDefault` and `mutating` MUST be the tool's `isMutating`.
- **tools-list-format**: The tool list MUST be serialised with sorted keys and without escaped slashes.
- **tools-call-unknown**: `POST tools/<name>` MUST answer 404 `not_found` with `Unknown tool '<name>'` when the host has no tool of that name, before reading the body.
- **tools-call-object**: `POST tools/<name>` MUST answer 400 `Expected a JSON object` when the body is not a JSON object; an empty body counts as an empty object.
- **tools-call-arguments**: `arguments` MUST be accepted as an absent or null value (becoming `{}`), a JSON object (re-encoded with sorted keys), or a string holding a JSON object (trimmed of surrounding whitespace and passed on as written).
- **tools-call-arguments-invalid**: `POST tools/<name>` MUST answer 400 with the message ``` `arguments` must be a JSON object or a string holding one ``` when `arguments` is a string that is not a JSON object, or is a number, boolean or array.
- **tools-call-caller-fallback**: A `caller` that is absent, null, empty or not a string MUST fall back to `AgentHandlers.defaultToolCaller`.
- **tools-list-invalid-schema**: A tool whose `inputSchemaJSON` is not valid JSON MUST still appear in the tool list, with an empty-object `input_schema`.
- **tools-call-caller**: The `caller` passed in a `ToolCallContext` MUST be the body's `caller` string when it is a non-empty string, and otherwise `AgentHandlers.defaultToolCaller`.
- **tools-call-outcome**: A successful call MUST answer 200 with the `ToolOutcome` encoded with `AgentsJSON`.
- **tools-call-tool-error**: A thrown `AgentToolError.invalidArguments` MUST answer 400 `bad_request`, any other `AgentToolError` 404 `not_found`, and any other thrown error 422 `unprocessable`, each with the error's localized description.
- **tools-call-no-permission-check**: The handler MUST NOT consult the tool's `permissionDefault` or `isMutating`; those fields are reported to the caller only, and any gating belongs to the host.
- **tools-methods**: `tools` with a method other than `GET`, `tools/<name>` with a method other than `POST`, and paths of three or more segments MUST answer the no-route reply.

### Model routes

- **models-dispatch**: `ModelHandlers` MUST match on method, first segment and segment count: an empty path (`GET`, `POST`), `plugins` and `resolve` (one segment, `GET`), otherwise the entry routes keyed by a UUID first segment.
- **models-list**: `GET` on an empty path MUST answer 200 with the registry's `ModelEntry` list.
- **models-create-conflict**: `POST` on an empty path with body `{entry, secrets?}` MUST answer 409 `conflict` with the message `A model entry with id <id> exists` when an entry with that id exists, which the registry reports as `duplicate`.
- **models-create**: `POST` on an empty path for a new id MUST call the registry's `create` with the entry and the optional secrets and answer 201 with the entry `create` returns.
- **models-create-decode**: `POST` on an empty path with a body that does not decode as `{entry, secrets?}` (for example `{}`) MUST answer 400.
- **models-create-invalid**: `POST` on an empty path MUST map registry errors through the shared map (see #requirements/models-error-map); an empty name, for example, is refused with `invalidEntry`.
- **models-secrets-never-returned**: No reply MUST carry a secret value; the reply entry names its secret fields only.
- **models-secrets-absent**: A request without `secrets` MUST leave an entry's stored secrets unchanged (the handler passes nil to `upsert`).
- **models-get**: `GET <id>` MUST answer 200 with the entry, or 404 when none exists.
- **models-put**: `PUT <id>` MUST answer 400 when the body entry's id differs from the path id, 404 when no entry has the path id, and otherwise upsert and answer 200 with the stored entry.
- **models-put-check-order**: `PUT <id>` MUST check the id mismatch before checking existence.
- **models-delete**: `DELETE <id>` MUST remove the entry and answer 204 empty, or 404 when none exists; a second delete MUST answer 404.
- **models-test**: `POST <id>/test` MUST answer 200 with the registry's `ModelTestResult` for the entry, or 404 when none exists.
- **models-list-models**: `GET <id>/models` MUST answer 200 with the registry's list of model names for the entry.
- **models-plugins**: `GET plugins` MUST answer 200 with the registry's `PluginSummary` list; it is matched before UUID parsing.
- **models-resolve-role**: `GET resolve` MUST answer 400 `` `role` is required `` when the `role` query value is absent or empty.
- **models-resolve**: `GET resolve?role=<r>` MUST answer 200 with the enabled entry holding the role, or 404 with `No enabled model entry has the role '<r>'`.
- **models-non-uuid**: A first segment other than the named ones that is not a UUID string MUST answer the no-route reply, and an unmatched method or sub-path on a UUID MUST answer the no-route reply.
- **models-error-map**: Registry errors MUST map as: `notFound` to 404 `not_found`; `invalidEntry` to 400 `bad_request`; `pluginNotInstalled`, `unknownTemplate` and `pluginIncompatible` (a plugin the host refused for an AIPluginKit ABI mismatch) to 422 `unprocessable`; `duplicate` to 409 `conflict`. The message MUST be the error's localized description.
- **models-create-atomic**: `POST` on an empty path MUST NOT check for an existing id itself; the registry's atomic `create` decides, so two concurrent creates of one new id answer one 201 and one 409.

### Concurrency and side effects

- **unmapped-error-500**: An error from the host or registry that is not mapped by `host-error-map`, `models-error-map` or `tools-call-tool-error` MUST answer a JSON 500 `internal` reply, never a thrown error, including when a concurrent delete makes the second of two check-then-delete calls fail.
- **host-isolation**: `AgentHandlers` MUST hold its `AgentHost` (an actor) and await every call; the handler set keeps no mutable state of its own and so MAY serve concurrent requests.
- **registry-isolation**: `ModelHandlers` MUST hold its `ModelRegistry` (a `Sendable` class) and keep no mutable state of its own.
- **side-effects-delegated**: The handlers MUST NOT touch files, the network or processes themselves; every side effect (storing agents and sessions, running turns and tools, storing models and secrets, testing a provider) happens inside the host or registry.
- **no-transport-auth**: The handlers MUST NOT authenticate or authorise a request; that is the mounting server's concern (the example host, roosterd, binds loopback only).
- **no-logging**: The handlers MUST NOT log; failures are returned in the reply only.

## Appearance

Not applicable — this is a request-routing and serialisation component, not a visual component.

## States

Not applicable — this is a stateless routing layer, not a visual component. Each `handle` call is independent; turn and session state lives in `AgentHost`.

## Accessibility

Not applicable — this is a request-routing and serialisation component, not a visual component.

## Conformance Test Vectors

Vectors are derived from `AgentHandlersTests.swift` (suites `HandlerRequest`, `AgentHandlers`, `ModelHandlers`) and from the route table in the source. Fixtures come from `AgentsTestSupport.swift`: a host with one enabled agent `helper` (model role `smart`), tools `echo` (auto, read-only), `bump` (ask, mutating) and `broken` (never, always throws), and a scripted model runtime.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-handlers-001 | request-method-uppercase, request-path-segments | `HandlerRequest(method: "get", path: "/tools//my%20tool/")` (test: segments) | method `GET`; path `["tools", "my tool"]` |
| agent-handlers-002 | response-error-shape, response-error-codes, response-status | `HandlerResponse.error(409, "conflict", "Busy")` (test: errorBody) | status 409; body decodes to `HandlerError(error: "conflict", message: "Busy")` |
| agent-handlers-003 | agents-list, agents-get | `GET agents`, then `GET agents/helper` (test: agents) | 200 with ids `["helper"]`; 200 |
| agent-handlers-004 | agents-get | `GET agents/ghost` (test: agents) | 404, code `not_found`, message `No agent with id 'ghost'` |
| agent-handlers-005 | agents-put-id-from-path, agents-put-save | `PUT agents/writer` body name Writer, prompt Write., model role smart (test: putAgent) | 200; host agent `writer` has name `Writer` |
| agent-handlers-006 | agents-put-id-mismatch | `PUT agents/writer` body id `other` (test: putAgent) | 400, code `bad_request`, message `The body's id 'other' does not match the path's 'writer'` |
| agent-handlers-007 | agents-put-decode | `PUT agents/writer` body with only `name` (test: putAgent) | 400, code `bad_request`, message starting `Malformed body: missing` |
| agent-handlers-008 | sessions-create, sessions-list, sessions-get, sessions-delete | create with agent helper and title T; list with query agent helper; get; delete; delete again (test: sessionLifecycle) | 201 with title `T`; list holds that id; detail info id matches; 204; 404 |
| agent-handlers-009 | sessions-create-agent-missing | `POST sessions` body agent `ghost` (test: sessionErrors) | 404, code `not_found`, message `No agent with id 'ghost'` |
| agent-handlers-010 | sessions-id-parse, sessions-get | `GET sessions/not-a-uuid`; `GET sessions/<random uuid>` (test: sessionErrors) | 404, code `not_found`, message `No session with id 'not-a-uuid'`; 404, code `not_found`, message `No session with id <uuid>` |
| agent-handlers-011 | messages-empty, messages-decode | `POST sessions/<id>/messages` with text of two spaces; with body `{}` (test: sessionErrors) | 400 `bad_request` `The message text is empty`; 400 `bad_request` starting `Malformed body: missing` |
| agent-handlers-012 | messages-stream | script `textDelta "Hi"` then end `end_turn`; `POST .../messages` text Hello (test: messageStreams) | `events` reply; envelopes `textDelta("Hi")`, `turnFinished(stopReason: "end_turn")` |
| agent-handlers-013 | messages-busy, interrupt | hanging runtime; first `POST .../messages`, second `POST .../messages`, then `POST .../interrupt` (test: interruptAndConflict) | second is 409; interrupt is 202; first stream ends with `turnFinished(stopReason: "interrupted")` |
| agent-handlers-014 | tools-list, tools-list-schema, tools-list-permission | `GET tools` (test: listsTools) | names `["echo","bump","broken"]`; `input_schema` of echo is an object; bump has `mutating` true and `permission` `ask` |
| agent-handlers-015 | tools-call-arguments, tools-call-caller, tools-call-outcome | `POST tools/echo` arguments object `{text: x}`, caller `cli` (test: runsTool) | `ToolOutcome.resultJSON` contains `"caller":"cli"` and `"text":"x"` |
| agent-handlers-016 | tools-call-arguments, default-tool-caller | `POST tools/echo` arguments the string `{"text":"y"}`, no caller (test: runsTool) | resultJSON contains `"caller":"external"` |
| agent-handlers-017 | tools-call-arguments-invalid | `POST tools/echo` arguments the string `not json` (test: runsTool) | 400, code `bad_request`, message `` `arguments` must be a JSON object or a string holding one `` |
| agent-handlers-018 | tools-call-unknown | `POST tools/nope` (test: toolErrors) | 404, code `not_found`, message `Unknown tool 'nope'` |
| agent-handlers-019 | tools-call-tool-error | `POST tools/broken` (test: toolErrors) | 422, error code `unprocessable`, message `The tool broke` |
| agent-handlers-020 | route-top-level, route-method-fallthrough | `GET nowhere`; `PATCH agents` (test: noRoute) | 404 `not_found` `No such route`; 404 `not_found` `No such route` |
| agent-handlers-021 | models-create, models-secrets-never-returned, models-create-conflict, models-create-atomic, models-list | `POST` empty path with entry (roles fast) and secrets apiKey `sk-secret`; same again; `GET` empty path (test: create) | 201, body lacks `sk-secret` and names `apiKey`, secret store holds it; 409; list holds the entry id |
| agent-handlers-022 | models-create-invalid, models-create-decode | `POST` entry with empty name; `POST` body `{}` (test: invalid) | 400 `bad_request` with the registry's reason; 400 `bad_request` starting `Malformed body: missing` |
| agent-handlers-023 | models-get, models-put, models-put-check-order, models-delete | get, put renamed entry, put to a random path id, put an absent entry, delete, get, delete (test: entryRoutes) | 200; 200 and registry shows `Renamed`; 400 `bad_request`; 404 `not_found`; 204 empty; 404 `not_found`; 404 `not_found` |
| agent-handlers-024 | models-resolve-role, models-resolve | `GET resolve` no query; role `fast`; role `smart` (test: resolve) | 400 `bad_request` `` `role` is required ``; 404 `not_found` `No enabled model entry has the role 'fast'`; 200 with the entry id |
| agent-handlers-025 | models-plugins, models-test, models-error-map | `GET plugins`; `POST <id>/test`; `POST <random uuid>/test` (test: pluginsAndTest) | one summary; decoded `ModelTestResult.isOK`; 404 `not_found` |
| agent-handlers-026 | sessions-id-parse, sessions-sub-path | `GET sessions/<uuid>/nothing` for an existing session | 404 no-route reply (from the route table; no test) |
| agent-handlers-027 | tools-call-object, tools-call-arguments | `POST tools/echo` with a JSON array body; with an empty body | 400 `Expected a JSON object`; 200 with arguments `{}` (from source; no test) |
| agent-handlers-028 | json-dates, json-encoder-format | encode a value holding a date and a slash-containing string with `AgentsJSON.encode` | ISO-8601 date text, keys in sorted order, slash not escaped (from source; no test) |
| agent-handlers-029 | host-error-map, messages-host-errors, messages-busy | `POST sessions/<id>/messages` for a disabled agent; for a session with a turn running (from source; no test for the disabled case) | 409 `conflict`, message `The agent 'helper' is disabled`; 409 `conflict`, message `Session <id> already has a turn running` |
| agent-handlers-030 | sessions-list | `GET sessions?agent=helper`, then `GET sessions?agent=ghost` (from source; the existing test covers only a present agent) | the first holds the helper sessions; the second answers 200 with an empty array |
| agent-handlers-031 | events-tail | `GET sessions/<id>/events` for an existing session; for a random session id (from source; no test) | an `events` reply; 404 `not_found`, message `No session with id <uuid>` |
| agent-handlers-032 | sessions-collection-methods, tools-methods | `DELETE sessions`; `POST tools`; `GET tools/echo`; `GET tools/echo/extra` (from source; no test) | each 404 `not_found` `No such route` |
| agent-handlers-033 | tools-call-tool-error | `POST tools/<name>` where the tool throws `AgentToolError.invalidArguments`; where it throws `AgentToolError.unknownTool` (from source; no test) | 400 `bad_request`, message `The arguments for '<name>' are not a JSON object`; 404 `not_found`, message `Unknown tool '<name>'` |
| agent-handlers-034 | tools-call-no-permission-check, no-transport-auth | `POST tools/bump` (permission `ask`, mutating) with arguments `{}` (from source; no test) | 200 with the tool's `ToolOutcome`; the handler asks nothing and the response carries no prompt |
| agent-handlers-035 | agents-empty-id-not-checked, agents-put-save | `PUT agents/writer` with a body whose `name` is empty (from source; no test) | 400 `bad_request`, message `An agent needs a name`, which is the host's reason; the handler added no check |
| agent-handlers-036 | response-encoded-failure | `HandlerResponse.encoded` of a value whose encoding throws (from source; no test) | status 500, code `internal`, message the encoder's localized description |
| agent-handlers-037 | decoding-error-description, decoding-error-400 | `POST sessions` with `{}`; with `{"agent": 1}` (from source; no test) | 400 ``Malformed body: missing `agent` ``; 400 ``Malformed body: `agent`: `` followed by the decoder's debug description |
| agent-handlers-038 | uuid-case-insensitive, models-non-uuid | `GET sessions/<uuid in upper case>` for an existing session; `GET not-a-uuid`; `GET <uuid>/nothing` on the model routes (from source; no test) | 200; 404 `No such route`; 404 `No such route` |
| agent-handlers-039 | segment-before-decode | `HandlerRequest(method: "GET", path: "/tools/a%2Fb/")` (from source; no test) | path `["tools", "a/b"]` |
| agent-handlers-040 | models-list-models | `GET <id>/models` for an existing entry (from source; no test) | 200 with the registry's list of model names |
| agent-handlers-041 | models-secrets-absent, models-put | `PUT <id>` with an entry and no `secrets` after a create that stored `apiKey` (from source; no test) | 200; the secret store still holds the earlier `apiKey` value |
| agent-handlers-042 | models-error-map | the registry throws `pluginNotInstalled`; `unknownTemplate` (from source; no test) | 422 `unprocessable` with the error's localized description, for each |
| agent-handlers-043 | tools-call-caller-fallback, tools-list-invalid-schema | `POST tools/echo` with `caller` null, `""` and `5`; `GET tools` with a tool whose schema text is `not json` (from source; no test) | each call's result carries `"caller":"external"`; the tool is listed with `input_schema` `{}` |
| agent-handlers-044 | models-create-atomic, models-create-conflict (test: concurrentModelCreates) | eight concurrent `POST` empty path with the same new entry id | exactly one answers 201; the others answer 409 `conflict` naming the id; the registry lists one entry |

SHOULD requirements: the component states none, so no SHOULD vectors are owed.

## Edge Cases
- **Empty path**: an empty `HandlerRequest.path` on `AgentHandlers` answers the no-route reply; on `ModelHandlers` it is the list and create route.
- **Empty body**: see `empty-body-defaults`: for `PUT agents/<id>` and `POST tools/<name>` an empty body reads as the empty object; for `POST sessions` and `POST sessions/<id>/messages` it fails decoding with 400.
- **Malformed JSON body**: see `malformed-json-body`; the two body readers give two different messages.
- **Whitespace-only message**: text of spaces, tabs or newlines answers 400 and never reaches the host (`messages-empty`).
- **Boundary id**: a session or entry id that is a valid UUID in any letter case is parsed (`uuid-case-insensitive`); a non-UUID session id answers 404, not 400.
- **Percent-encoded segments**: see `segment-before-decode`; a tool name containing an encoded space arrives as one decoded segment.
- **Path longer than the route**: extra segments after a recognised session sub-route are ignored (`sessions-extra-segments`); extra segments on `agents` and `tools` answer no-route.
- **Missing caller**: see `tools-call-caller-fallback`.
- **Invalid tool schema**: see `tools-list-invalid-schema`.
- **Concurrent calls**: the handler sets hold no mutable state, so concurrent `handle` calls are safe at this layer. A second message to a session with a turn running answers 409. Concurrent creates of the same new model id answer one 201 and one 409, because the registry's `create` checks and inserts in one transaction (`models-create-atomic`).
- **Check-then-act on delete**: `DELETE sessions/<id>` and `DELETE <id>` check existence and then delete as two calls; a concurrent delete can make the second call surface the host or registry error, which `unmapped-error-500` and the error maps turn into a JSON error.
- **Stream cancellation**: the `events` reply is a plain `AsyncStream`; the handler adds no cancellation, timeout or keep-alive, and the mounting server owns client disconnects (a fact: no such code exists here).
- **Unreachable dependency**: the host and registry are in-process; a database or plugin failure inside them surfaces as an unmapped error and answers 500 `internal` (`unexpected-error-500`). A plugin that is not installed answers 422 on the model routes (`models-error-map`).
- **Offline or disconnected state**: the component performs no network I/O itself; provider reachability is exercised only through `POST <id>/test` and `GET <id>/models`, whose results and failures come from the registry.
- **Encoding failure**: a reply value that cannot be encoded answers 500 `internal` (`response-encoded-failure`).
- **Non-ASCII**: bodies are UTF-8 through `JSONSerialization` and `JSONEncoder`; non-ASCII text passes through unchanged and slashes are not escaped.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| host | `AgentHost` | required | Injected into `AgentHandlers.init(host:)`; supplies agents, sessions, turns, tools |
| registry | `ModelRegistry` | required | Injected into `ModelHandlers.init(registry:)` |
| `AgentHandlers.defaultToolCaller` | String | `external` | Caller a tool sees when the request names none |
| mount point | server choice | example host (roosterd): `/agent` and `/models` | The server strips the mount and passes the remaining segments as `HandlerRequest.path` |
| `agent` query | String | absent | Filters `GET sessions` by agent id |
| `role` query | String | required on resolve | Role looked up by `GET resolve` |

There are no environment variables, settings keys, timeouts or retry settings in this component.

## Deep Linking

Not applicable: the routes are HTTP-style handler paths relative to a server mount, not application deep links; the source registers no URL scheme.

## Localization

Not applicable as a feature, with one fact to carry: every error `message` is an English string written in the source (for example `No such route`, `The message text is empty`) or the localized description of a host, registry or tool error, and nothing is externalised. The error `code` values are stable machine identifiers and MUST NOT be translated.

## Accessibility Options

Not applicable: the component has no visual or audible output, so Reduce Motion, Increase Contrast and Differentiate Without Color have nothing to act on.

## Feature Flags

Not applicable: the source reads no flag or setting; the set of routes is fixed by the code.

## Analytics

Not applicable: the source emits no events or metrics.

## Privacy

- **Data collected**: none by the handlers. Bodies carry agent definitions, session titles, message text, tool arguments and results, and model entries with optional `secrets`.
- **Storage**: none in the handlers; the host and registry store agents, sessions and entries, and the registry's secret store holds secret field values.
- **Transmission**: replies never carry a secret value (a `ModelEntry` names its secret fields only); request bodies to `POST` and `PUT` model routes MAY carry secrets in the clear on the server's transport, which the example host (roosterd) binds to loopback.
- **Retention**: not decided here; owned by the host and registry.

## Logging

Not applicable: the source contains no log call. Errors are returned in the reply body and nowhere else.

## Platform Notes

- **SwiftUI**: A SwiftUI client does not call these types. It calls the HTTP surface through a client (the CLI decodes with the public `AgentsJSON`) or, in process, `AgentHandlers.handle` directly.
- **Compose**: Start from a Ktor routing block or a plain suspend function `handle(request): HandlerResponse` with a sealed class for the two reply cases (a JSON body or a `Flow` of envelopes). Use `kotlinx.serialization` configured to write ISO-8601 instants and sorted keys, and `Flow` where Swift uses `AsyncStream`. Percent-decoding and the status mapping are the same; Kotlin has no direct equivalent of `JSONSerialization`, so the loose-object routes (tool arguments, agent PUT) use `JsonObject`.
- **React/Web**: Start from fetch calls from the client side, or on a Node server an Express or Fastify route table. Model the reply as a union type of a JSON reply and an async iterable of envelopes relayed as `text/event-stream` with the event `type` as the event name. Use `JSON.stringify` with a replacer that sorts keys if byte-identical bodies matter; dates are ISO strings. JavaScript is single-threaded, so the check-then-act races noted above narrow to interleavings across awaits.
- **AppKit / UIKit**: No UI. An AppKit or UIKit app embeds the handler set in process, or reaches it over loopback HTTP as the example host does; the same Swift files apply on macOS, and the types are Foundation-only, so they build for iOS as well if the agent host does.
- **WinUI 3**: Build the handler as an ASP.NET Core minimal API mounted with `MapGroup("/agent")` and `MapGroup("/models")` in a Windows service hosted through `IHostedService` (or `BackgroundService`) beside the app, which reaches it with `HttpClient` on loopback. Represent `HandlerRequest` with `HttpContext` (method, `RouteValues`, `Query`, body stream) or a small record for in-process calls; percent-decoding is done by the framework. Replace the two-case enum with `IResult` (`Results.Json`, `Results.StatusCode`) and a streamed `text/event-stream` response written from an `IAsyncEnumerable` of envelopes. Use `System.Text.Json` with `JsonSerializerOptions` for ISO-8601 dates (the default for `DateTimeOffset`) and sorted keys through a custom `JsonConverter` or a `JsonNode` pass, and `JsonObject` for the loose bodies. Hold the host as an injected singleton service, use `Task` and `async` throughout, and map exceptions with a typed `switch` to the same status codes (a `UseExceptionHandler` middleware or an `IExceptionHandler`). Stream cancellation arrives as `HttpContext.RequestAborted`, which the source has no equivalent for. Secrets belong in Windows Credential Locker (`Windows.Security.Credentials.PasswordVault`) behind the registry's secret-store seam.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Handlers/` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/Agents/Support/AgentsJSON.swift` | unverified |

## Design Decisions

**Decision**: The handlers take a transport-neutral `HandlerRequest` and return a `HandlerResponse` instead of binding to an HTTP server type.
**Rationale**: The same routes are tested without a socket (the test suite calls `handle` directly) and mounted by roosterd under any prefix; the mount is the server's choice.
**Approved**: pending

**Decision**: `PUT agents/<id>` takes the id from the path and refuses a body whose `id` differs.
**Rationale**: A path is the resource identity; a mismatch is more likely a client bug than an intended rename, so it answers 400 rather than saving under either id.
**Approved**: pending

**Decision**: A non-UUID session id answers 404, not 400, and unmatched sub-paths answer 404 `No such route`.
**Rationale**: To a client, an id that cannot name a session names no session; the same 404 serves both, with the message saying which.
**Approved**: pending

**Decision**: `POST tools/<name>` accepts `arguments` as an object or as a string holding an object, and defaults `caller` to `external`.
**Rationale**: Command-line and tool-use clients often hold arguments as text; accepting both avoids a client re-encode. `external` marks a call that did not come from an agent turn, so a tool can distinguish it.
**Approved**: pending

**Decision**: A thrown `AgentToolError.invalidArguments` answers 400 `bad_request`, any other thrown `AgentToolError` answers 404 `not_found`, and any other thrown tool error answers 422 `unprocessable`.
**Rationale**: `invalidArguments` means the caller sent arguments that are not a JSON object, a client error, so 400. Any other `AgentToolError` (today only `unknownTool`) names a tool that does not exist, so 404. Any error the tool throws itself means it received a request it could not process, so 422. This is the `tools-call-tool-error` requirement.
**Approved**: pending

**Decision**: The tool list reports each tool's `permission` and `mutating` flags, and the call route does not enforce them.
**Rationale**: A caller sees the policy, but gating belongs to the host's turn loop; an external call through `POST tools/<name>` is a direct request and adds no prompt of its own. This is the `tools-call-no-permission-check` requirement.
**Approved**: pending

**Decision**: The tool-list `input_schema` falls back to an empty object when the stored schema text is not valid JSON.
**Rationale**: One tool with a bad schema must not make the whole list unavailable; the lossy projection is deliberate and silent in the reply.
**Approved**: pending

**Decision**: `ModelHandlers` never returns secret values and treats an absent `secrets` as "leave stored secrets alone".
**Rationale**: Secrets are write-only over this surface, so an edit of a name or role does not force the caller to resend a key it cannot read back.
**Approved**: pending

**Decision**: `AgentsJSON` is one public dialect (ISO-8601 dates, sorted keys, unescaped slashes) with a fresh coder per call.
**Rationale**: Stored rows, HTTP bodies and test fixtures read the same and a CLI client decodes identically; `JSONEncoder` and `JSONDecoder` are not `Sendable`, so sharing one instance across tasks would not compile under strict concurrency.
**Approved**: pending

**Decision**: The decoding-error description is `HandlerError.describe(_:)`, beside `HandlerError` in `HandlerRequest.swift`.
**Rationale**: Both sets must word a malformed body the same way, so there is one description function. Putting it with the request and error types both sets already use keeps `ModelHandlers` and `AgentHandlers` independent of each other, with the `decoding-error-description` wording unchanged.
**Approved**: pending

**Decision**: `POST` to the model routes calls the registry's atomic `create` and maps its `duplicate` error to 409.
**Rationale**: A separate read for an existing id followed by `upsert` (an insert-or-update) let two concurrent creates of one new id both answer 201, the later write winning silently. The registry's `create` checks and inserts in one transaction, so the handler does no read of its own and the conflict answer cannot race (`models-create-atomic`).
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | privacy-and-data |

The handlers keep routing, status mapping and serialisation apart from the host, registry and tools they call, which is the separation-of-concerns pass. Unit-test coverage is partial: the suites in `AgentHandlersTests.swift` exercise every route family, but several behaviors here have no test (extra path segments, array or empty bodies for tool calls, an unparseable tool schema, the `agent` filter for a missing agent, the `events` tail route and the model `models` route), so vectors 026 to 028 and every 029 to 043 vector marked "no test" are derived from source only. Error handling is explicit: every failure becomes a JSON reply with a code and message and `handle` never throws, the only silent projection being the tool-schema fallback documented above. The model routes keep secrets write-only and the tests assert that a posted secret does not appear in the reply.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-25 | Mike Fullerton | POST models calls the registry's atomic create (duplicate maps to 409); the decoding-error description is the shared HandlerError.describe. |
| 1.0.0 | 2026-11-25 | Mike Fullerton | Initial creation |
