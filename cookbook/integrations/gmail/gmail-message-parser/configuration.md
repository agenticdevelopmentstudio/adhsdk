
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dto` | `GmailMessageDTO` | none | The decoded `format=full` message. |
| `connectionId` | `String` | none | Copied to the record. |
| `existingId` | `String?` | none | Local record id to keep; nil generates a new one. |
| `now` | `Date` | `Date()` | The date given to a message with neither a numeric `internalDate` nor a readable `Date` header. |

There are no environment variables, settings keys or injected dependencies; `MailClassifier` and `IntegrationClock` are called directly.

