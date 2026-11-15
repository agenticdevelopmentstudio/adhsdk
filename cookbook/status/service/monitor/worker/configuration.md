
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workerData.storage` | `MessagePort \| undefined` | `undefined` → open own connection | Transferred port to the host's database thread. When supplied, the worker builds its `Storage` with `connectStorage` and holds no connection (storage-port-preferred). |
| `workerData.db` | `LibsqlConnection` (`{ url: string; authToken?: string }`) \| `undefined` | none — required only when `storage` is absent | Connection descriptor handed to the `Worker` at construction. With no `storage`, `url` MUST be a non-empty string or the module throws at boot (storage-or-connection-required). |
| `workerData.config` | `StatusConfig` | none — required | Threaded unchanged into `runMonitorCycle` for every `CycleRequest` this worker instance processes (storage-and-config-passed-unchanged). |
| `workerData.cooldowns` | `SharedArrayBuffer \| undefined` | `undefined` → private, thread-local registry | Adopted via `attachCooldownState`. When supplied by the spawner (`MonitorWorkerClient.spawn`, external), this worker shares the same provider-cooldown state as whichever thread supplied it. |
| `workerData.hogqlLock` | `SharedArrayBuffer \| undefined` | `undefined` → private, thread-local lease | Adopted via `attachHogqlLockState`, so this cycle's PostHog HogQL queries and the API thread's dashboard queries never overlap (hogql-lock-attached-before-listening). |
| `CycleRequest.seq` (per message) | `number` | none — caller-assigned | Echoed back unchanged in the `CycleReply`; this file assigns it no meaning beyond matching a reply to its request. |
| `CycleRequest.fullSync` (per message) | `boolean` | none — caller-supplied | Passed unchanged as `runMonitorCycle`'s `opts.fullSync`. |

