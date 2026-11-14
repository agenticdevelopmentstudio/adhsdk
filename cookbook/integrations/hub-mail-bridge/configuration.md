
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `HubMailStore` | required | The mirror the bridge reads and writes label changes into. |
| writeLabels | `@Sendable (HubMailLabelWrite) async throws -> Void` | required | Posts one `modify_labels` action; production passes `HubMailSender.modifyLabels`. |
| syncNow | `@Sendable () async -> Void` | required | Runs one pull; production passes `HubMailSync.syncNow`. |

