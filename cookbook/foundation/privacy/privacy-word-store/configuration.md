
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `accessGroup` | `String?` | none (required argument) | The keychain access group, chosen by the app's entitlements; nil omits the attribute. |
| `service` | `String` | `com.agenticdevelopmentstudio.privacy-words` | The keychain service attribute. |
| `account` | `String` | `privacy-words` | The keychain account attribute. |
| `reason` | `String` | none | Parameter of `authenticate`, shown in the system authentication prompt. |
| `context` | `LAContext?` | nil | Parameter of `load`; an authenticated context from `authenticate` for reading an item saved under the older guard. |
