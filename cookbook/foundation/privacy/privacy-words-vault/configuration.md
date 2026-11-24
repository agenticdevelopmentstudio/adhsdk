
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `store` | `PrivacyWordStore` | none (required) | Injected keychain store; its `service` and `account` also name the change notification. |
| Upgrade reason | `String` | `upgrade how the privacy words are stored. This is asked once` | Fixed prompt text used by `loadUpgradingIfNeeded`. |

The distributed notification center and the process identifier are not injectable: the vault always uses `DistributedNotificationCenter.default()` and the identifier of the running process. The vectors that involve another app (009, 014, 015) are exercised with two processes, or by posting the change notification from the test with a different string object.
