
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | `BoundedDatabase` | none | The injected SQLite handle. The store migrates it on creation and routes every read and write through it. |
| `inListChunkSize` | `Int`, internal static | 500 | Ids bound per `IN (...)` statement in `tombstoneMessages(connectionId:externalIds:)`; the source comment says it is "well under SQLite's 32766-variable limit". |
| `MessageQuery.limit` | `Int` | 50 | Rows per page; clamped to at least 0. |
| `MessageQuery.offset` | `Int` | 0 | Rows skipped; clamped to at least 0. |
| `MessageQuery.since`, `until`, `after` | `String?`, `String?`, `MessageKey?` | nil | Optional lower bound, upper bound and resume key. |
| `MessageQuery.labelIds`, `anyLabelIds` | `[String]` | empty | Labels a message must all carry, and labels of which it must carry at least one. |
| `includingDeleted` | `Bool` | false | Lets `message(...)` return a tombstoned row. |
| Read and write deadlines | `Duration`, on `BoundedDatabase` | 10 seconds, 60 seconds | Set when the database is built, not by the store. |

The store reads no environment variable and no settings key.

