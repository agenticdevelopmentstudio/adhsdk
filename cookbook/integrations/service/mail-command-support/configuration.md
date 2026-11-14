
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (encode) | `Encodable` | none, required | The value to print. |
| `text` (normalize) | `String` | none, required | The raw `since` or `until` value. |
| `edge` (normalize) | `MailDateBound.Edge` | none, required | `start` or `end`; used only for date-only text. |

There are no environment variables, settings keys or injected dependencies. The one fixed dependency is `IntegrationClock.string(from:)`, which writes the UTC timestamp for a parsed instant; it lives in `Mail/Model/IntegrationRecords.swift` ([adhsdk.ingredient.integrations.model.integration-records](cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f)).

