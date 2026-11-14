
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `settings` | `MailSyncSettings` | `.default` | Input to `GmailQuery.fullSync`: `includeArchived` false, `includeSpam` false, `includeTrash` false, `windowDays` 30, `pollIntervalMinutes` 15 (only `includeArchived`, `includeSpam`, `includeTrash` and `windowDays` affect the query) |
| `now` | `Date` | none | Clock injected into `GmailQuery.fullSync` so tests are deterministic |
| `query` | `String` | none | Gmail search syntax passed to `listMessageIds` and `searchMessageIds` |
| `maxResults` | `Int` | none | Page size parameter of `searchMessageIds` only |
| list page size | `Int` | 500 | Not a protocol parameter: `GmailRESTClient.listMessageIds` has no `maxResults` argument and always requests 500 ids per page |
| `accessToken` | `@Sendable () async throws -> String` | none | Token supplier passed to the `GmailRESTClient` initializer, not to the protocol; called for each request |

