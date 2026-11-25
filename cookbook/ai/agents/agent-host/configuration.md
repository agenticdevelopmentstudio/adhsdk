
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | `BoundedDatabase` | required | Where the host keeps its tables; the daemon passes `events.sqlite`. |
| `registry` | `ModelRegistry` | required | Resolves model selectors and supplies the plugin search paths. |
| `tools` | array of `AgentTool` | required | The one tool set shared by every agent; exposed as `tools`. |
| `defaults` | array of `AgentDefinition` | required | Agents inserted when their id is absent; an edited one is kept. |
| `runtime` | `DaemonAIChat.PluginRuntime` | `.live` | Loads a plugin and runs a built request; tests inject a scripted one. |
| `maxToolRounds` | `Int` | 16 | Model round trips a turn may make before it fails; a value below 1 is taken as 1. |
| `AgentDefinition.defaultDeadlineSeconds` | `Double` | 30 | Default `deadlineSeconds` of a definition; the host does not use it. |

Two values are constants, not options: `AgentHost.agentCaller` (`"agent"`, the caller name tools see on a turn's tool runs) and the answer room (4096 tokens added to the thinking budget to make `maxTokens`).

The host reads no environment variable and no settings key.

