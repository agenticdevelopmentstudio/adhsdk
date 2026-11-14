
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `HubMailStore` | required | The mirror the bridge reads and writes label changes into. |
| writeLabels | `@Sendable (HubMailLabelWrite) async throws -> Void` | required | Posts one `modify_labels` action; production passes `HubMailSender.modifyLabels`. |
| syncNow | `@Sendable () async -> Void` | required | Runs one pull; production passes `HubMailSync.syncNow`. |

`HubMailService`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| syncInterval | `TimeInterval?` | 300 | Seconds between background pulls; nil for none (the `syncNow` request still pulls). |
| connect | `@MainActor () throws -> Connection` | required | Builds the sync and label writer for the identity that just signed in. |

`HubMailService.live(databaseURL:deviceId:syncInterval:sessionStore:configuration:)` defaults `sessionStore` to the Keychain store `HubAccount.live` uses (`adh.api`) and `configuration` to `.fromBundle()`.
