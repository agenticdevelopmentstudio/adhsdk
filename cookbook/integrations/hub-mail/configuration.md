
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| database | `BoundedDatabase` | required | The SQLite file the mirror and the sync bookkeeping live in, apart from any direct-Gmail database. |
| transport | `any SyncTransport` | required | Usually `ADHSyncTransport(api:)`; tests pass a scripted one. |
| deviceId | `String` | required | The engine's device id. |
| client | `any APIProtocol` | required | The hub client the sender posts through. |

