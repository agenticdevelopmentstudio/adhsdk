
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `settings` | `MailSyncSettings` | `.default` | Input to `GmailQuery.fullSync`: `includeArchived` false, `includeSpam` false, `includeTrash` false, `windowDays` 30, `pollIntervalMinutes` 15 (only the first four affect the query) |
| `now` | `Date` | none | Clock injected into `GmailQuery.fullSync` so tests are deterministic |
| `query` | `String` | none | Gmail search syntax passed to `listMessageIds` and `searchMessageIds` |
| `maxResults` | `Int` | none | Page size for `searchMessageIds`; `GmailRESTClient.listMessageIds` fixes it at 500 |
| `accessToken` | `@Sendable () async throws -> String` | none | Token supplier passed to the `GmailRESTClient` initializer, not to the protocol; called for each request |

