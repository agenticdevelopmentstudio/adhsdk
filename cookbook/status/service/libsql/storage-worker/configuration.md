
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workerData.db.url` | `string` | none, required | Database location: `file:<path>` for an embedded SQLite file, or an https/libsql URL for remote libSQL. An empty or missing value throws at load. |
| `workerData.db.authToken` | `string \| undefined` | `undefined` | Auth token for a remote libSQL URL, passed to `openLibsql`. |
| `StorageWorkerRequest.attach` | `MessagePort` | none, required per message | The port a connecting thread is served on; transferred in the message's transfer list. |
| Migrations folder | path | `MIGRATIONS_FOLDER` from `client.ts` | Not configurable here; `migrateDb(db)` is called with the default. |
| PRAGMA settings | fixed | WAL, `busy_timeout` 5000, `synchronous` NORMAL | Applied only to `file:` URLs by `tuneDbForConcurrency`; not configurable here. |

