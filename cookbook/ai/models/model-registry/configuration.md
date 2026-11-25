
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storeURL` | URL | `~/Library/Application Support/com.agenticdevelopmentstudio.models/models.sqlite` | The SQLite file; its parent directory is created. |
| `database` | `BoundedDatabase` | opened at `storeURL` | The designated initializer takes an open database; a test passes `:memory:`. |
| `secrets` | `ModelSecretStore` | `SharedGroupModelSecrets()` | Where secret values live. |
| `runtime` | `DaemonAIChat.PluginRuntime` | `.live` | Loads plugins, runs requests and discovers descriptors; a test substitutes a scripted one. |
| `searchPaths` | list of URL | `DaemonAIChat.pluginSearchPaths()` | Where plugins are looked for; the agent host loads from the same places. |
| `makeSignal` | `@Sendable` factory of `CrossProcessSignal` | A `DarwinNotificationSignal` named `com.agenticdevelopmentstudio.models.changed` | One instance posts; each `changes` stream observes its own. |
| `keychain` | `AIProviderSecretKeychain` (secret store) | The shared group when entitled, else the process Keychain | Where `SharedGroupModelSecrets` stores values. |
| `changeNotificationName` | optional string (secret store) | `AIProviderSharedSecretsProvider.changeNotificationName` | The Darwin notification the secret store posts after a write; nil posts nothing. |

The registry reads no environment variable and no settings key.

