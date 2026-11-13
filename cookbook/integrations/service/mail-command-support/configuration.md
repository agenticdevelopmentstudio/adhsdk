
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (encode) | `Encodable` | none, required | The value to print. |
| `text` (normalize) | `String` | none, required | The raw `since` or `until` value. |
| `edge` (normalize) | `MailDateBound.Edge` | none, required | `start` or `end`; used only for date-only text. |
| `IntegrationClock.string(from:)` | `(Date) -> String` | fixed | Writes the UTC timestamp for a parsed instant; it lives in `Integrations/Model/IntegrationRecords.swift`. |

There are no environment variables, settings keys or injected dependencies.

