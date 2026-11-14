
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

`HubMailLocation`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| databaseURL | `URL` | required | The mirror's database file. |
| deviceId | `String` | required | The stable device id the sync cursor is filed under. |
| appFolder | `String` | required for `app(_:)` | The folder under Application Support that holds `hub-mail.db`. |
| defaults | `UserDefaults` | `.standard` | Where `app(_:)` and `deviceId(defaults:)` keep the device id. |
| deviceIdKey / key | `String` | `HubMailLocation.defaultDeviceIdKey` (`hub_mail_device_id`) | The defaults key the device id is stored under. |
| fileManager | `FileManager` | `.default` | Supplies the Application Support directory for `app(_:)`. |

`HubMailService.live(at:syncInterval:)` takes a `HubMailLocation` and `syncInterval` (default 300), and uses the defaults below.

`HubMailService.live(databaseURL:deviceId:syncInterval:sessionStore:configuration:)` defaults `sessionStore` to the Keychain store `HubAccount.live` uses (`adh.api`) and `configuration` to `.fromBundle()`.
