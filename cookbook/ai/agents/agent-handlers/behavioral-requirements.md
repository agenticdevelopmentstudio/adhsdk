
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
- **decoding-error-description**: The description of a `DecodingError` MUST be ``missing `<key>` `` for a missing key, and otherwise the dotted coding path in backticks, a colon and the decoder's debug description (or the debug description alone when the path is empty).
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
- **models-create-conflict**: `POST` on an empty path with body `{entry, secrets?}` MUST answer 409 `conflict` with a message naming the id when an entry with that id exists.
- **models-create**: `POST` on an empty path for a new id MUST call the registry's `upsert` with the entry and the optional secrets and answer 201 with the stored entry.
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
- **models-error-map**: Registry errors MUST map as: `notFound` to 404 `not_found`; `invalidEntry` to 400 `bad_request`; `pluginNotInstalled` and `unknownTemplate` to 422 `unprocessable`. The message MUST be the error's localized description.
- **models-create-check-order**: The conflict check on `POST` MUST read the registry first and call `upsert` afterwards; see the Design Decision on the create race.

### Concurrency and side effects

- **unmapped-error-500**: An error from the host or registry that is not mapped by `host-error-map`, `models-error-map` or `tools-call-tool-error` MUST answer a JSON 500 `internal` reply, never a thrown error, including when a concurrent delete makes the second of two check-then-delete calls fail.
- **host-isolation**: `AgentHandlers` MUST hold its `AgentHost` (an actor) and await every call; the handler set keeps no mutable state of its own and so MAY serve concurrent requests.
- **registry-isolation**: `ModelHandlers` MUST hold its `ModelRegistry` (a `Sendable` class) and keep no mutable state of its own.
- **side-effects-delegated**: The handlers MUST NOT touch files, the network or processes themselves; every side effect (storing agents and sessions, running turns and tools, storing models and secrets, testing a provider) happens inside the host or registry.
- **no-transport-auth**: The handlers MUST NOT authenticate or authorise a request; that is the mounting server's concern (the example host, roosterd, binds loopback only).
- **no-logging**: The handlers MUST NOT log; failures are returned in the reply only.

