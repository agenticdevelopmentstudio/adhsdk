
Agent Handlers is the HTTP-shaped front door to the agent framework, written so that no server is involved. A hosting process (the example host, roosterd, mounts the agent routes at `/agent` and the model routes at `/models`; any mount point works) converts each incoming request into a `HandlerRequest` (method, path segments below the mount, query dictionary, body bytes), calls `handle` on a handler set, and relays the returned `HandlerResponse`: either a status with a JSON body, or a stream of `AgentEnvelope` values that the server forwards, for the example host as server-sent events with the event `type` as the event name.

The component is four cooperating pieces:

- `HandlerRequest`, `HandlerResponse` and `HandlerError`: the transport-neutral request, the two-case reply, and the `{"error":"<code>","message":"..."}` error body shared by every handler.
- `AgentHandlers`: the agent host's routes (agents, sessions, messages, interrupt, event tail, tools list and tool call).
- `ModelHandlers`: the model registry's routes (entries, test, model list, plugins, role resolution).
- `AgentsJSON`: the single JSON dialect (ISO-8601 dates, sorted keys, unescaped slashes) used for every stored row, body and fixture.

The agent host (`AgentHost`, [Agent Host](cookbook:d711486e-1195-417b-9baf-7315354dae8d)), the model registry (`ModelRegistry`, [Model Registry](cookbook:12d36a57-8d7d-454e-a2ee-44effbd9e93b)) and the tool protocol (`AgentTool`, `ToolOutcome`, `ToolCallContext`, [Agent Tool](cookbook:86788f50-7b85-4659-b7df-8c560e082f76)) have their own ingredients. This ingredient specifies how requests map onto them and how their errors map onto statuses.

The source is Swift in `AgenticDeveloperHubSDK`: `Agents/Handlers/HandlerRequest.swift`, `AgentHandlers.swift`, `ModelHandlers.swift` and `Agents/Support/AgentsJSON.swift`, with `Sendable` handler structs over an actor host, an `async` `handle`, `AsyncStream` for events and `JSONSerialization` for the routes that need loose objects. There is no view code.

Boundary: the handlers only route, map and serialise. They do not authenticate, authorise, gate on a tool's permission, validate an agent beyond the id check, log, or touch files, the network or processes; each of those belongs to the mounting server, the host or the registry.

