
The worker itself logs nothing; its signals are the `StorageWorkerReply` message and thrown errors. The one log line produced while it runs comes from the `createStorageServer` it hosts.

Subsystem: none | Category: `storage`

| Event | Level | Message |
|-------|-------|---------|
| A single Storage call takes 2000 ms or more | warn | `[storage] slow call <path> <ms>ms` |

