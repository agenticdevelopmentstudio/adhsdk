
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `caller` | `String` | `AgentHandlers.defaultToolCaller` (`external`) | The caller name every remote run reports to the host |
| `transport` | `@Sendable (HandlerRequest) async throws -> HandlerResponse` | none (required) | Delivers requests to the host's agent mount: HTTP, XPC, or an in-process `AgentHandlers` |
| `ToolCallContext.caller` | `String` | none (required) | The caller of a local run; ignored by remote tools |
| `ToolCallContext.agentId` | `String?` | nil | The agent running the tool, from an agent's turn |
| `ToolCallContext.sessionId` | `UUID?` | nil | The session of the turn |

