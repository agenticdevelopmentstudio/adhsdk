
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rawEventType` | `String` | caller | The event name every classification function takes |
| `hookData` | `[String: Any]` | caller | The event's payload; read keys are `notification_type`, `source` and `agent_id` |
| `ambientEventTypes`, `offTurnEventTypes`, `waitingNotificationTypes`, `turnEndingEventTypes`, `interruptedEventType` | `Set<String>` and `String` | fixed | Constants; not injectable |

