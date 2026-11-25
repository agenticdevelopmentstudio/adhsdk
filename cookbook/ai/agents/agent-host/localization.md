
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none | `No agent with id '<id>'` | `AgentHostError.agentNotFound` description |
| none | `The agent '<id>' is disabled` | `AgentHostError.agentDisabled` description |
| none | `No session with id <UUID>` | `AgentHostError.sessionNotFound` description |
| none | `Session <UUID> already has a turn running` | `AgentHostError.turnInProgress` description |
| none | `An agent needs an id`, `An agent needs a name` | `invalidAgent` reasons from `save` |
| none | `No model is available: add and enable one in the model registry` | `turn_failed` message |
| none | `The agent used tools for <N> rounds without answering` | `turn_failed` message |
| none | `<tool> failed` | `tool_finished` summary on a tool error |

Every string is a hardcoded English literal; none goes through a localization table. Error descriptions of other types and the `{"error":...}` result are passed on as they arrive.

