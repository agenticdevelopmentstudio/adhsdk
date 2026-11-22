
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Sessions.StenographerBilling.settingsKeyPrefix` | `String` (constant) | `"stenographer_billing_"` | The settings-table key prefix Stenographer's app writes its billing knobs under and its daemon reads them under; passed to `BillingSettingsKeys(prefix:)`. Not overridable. |
| `VisibleText` allowlist | fixed | Letters, numbers, punctuation, symbols, space separators, minus default-ignorable code points | Compiled in; no parameter, environment variable or settings key changes it. |

The namespace takes no parameters, reads no environment variables or settings keys, and has no injected dependencies.

