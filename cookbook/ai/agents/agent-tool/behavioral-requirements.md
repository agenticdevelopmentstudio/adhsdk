
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

