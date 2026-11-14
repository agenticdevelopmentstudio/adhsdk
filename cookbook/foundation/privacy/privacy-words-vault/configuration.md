
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `store` | `PrivacyWordStore` | none (required) | Injected keychain store; its `service` and `account` also name the change notification. |
| `reason` | `String` | none | Parameter of `authenticate` and `save`, shown in the system authentication prompt. |
| Upgrade reason | `String` | `upgrade how the privacy words are stored. This is asked once` | Fixed prompt text used by `loadUpgradingIfNeeded`. |

