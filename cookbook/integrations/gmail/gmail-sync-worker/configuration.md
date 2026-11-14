
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api` | `any GmailAPI` | none | The Gmail client; the worker calls `labels`, `profile`, `listMessageIds`, `history` and `message`. |
| `store` | `IntegrationsStore` | none | The local mirror; receives labels, messages, tombstones and the sync state. |
| `now` | `@Sendable () -> Date` | `Date.init` | The clock, injected so tests fix time. |
| `connection` (argument to `sync`) | `IntegrationConnection` | none | Supplies `id`, `syncCursor` and `syncSettings`. |
| `syncSettings.includeArchived`, `includeSpam`, `includeTrash` | `Bool` | false, false, false | Decide, through `allows(_:)` and `GmailQuery.fullSync`, which mail classes are listed and kept; filed mail is always kept. |
| `syncSettings.windowDays` | `Int` | 30 | How many days back the window reaches; validated elsewhere to 1 through 3650. |
| `fetchConcurrency` | `Int` constant | 8 | Message fetches in flight at once. |
| `upsertBatchSize` | `Int` constant | 100 | Messages handed to the store per batch. |

There are no environment variables or settings keys read by the worker. `syncSettings.pollIntervalMinutes` exists on the settings type but is not read here; the caller schedules runs.

