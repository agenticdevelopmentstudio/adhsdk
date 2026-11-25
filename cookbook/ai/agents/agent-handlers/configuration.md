
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| host | `AgentHost` | required | Injected into `AgentHandlers.init(host:)`; supplies agents, sessions, turns, tools |
| registry | `ModelRegistry` | required | Injected into `ModelHandlers.init(registry:)` |
| `AgentHandlers.defaultToolCaller` | String | `external` | Caller a tool sees when the request names none |
| mount point | server choice | example host (roosterd): `/agent` and `/models` | The server strips the mount and passes the remaining segments as `HandlerRequest.path` |
| `agent` query | String | absent | Filters `GET sessions` by agent id |
| `role` query | String | required on resolve | Role looked up by `GET resolve` |

There are no environment variables, settings keys, timeouts or retry settings in this component.

