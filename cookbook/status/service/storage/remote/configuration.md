
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` | `Storage` | required | The store the server serves, passed to `createStorageServer` |
| `port` | `MessagePort` | required | The port passed to `serve` (one per user thread) or to `connectStorage` |
| `SLOW_CALL_MS` | number | 2000 | Duration at which a call is logged as slow; a module constant, not configurable by the caller |

