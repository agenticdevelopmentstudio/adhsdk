
The storage thread module is the host's handle to the status server's database thread. The host calls `startStorageThread` once at boot, in place of opening a database connection itself. The call spawns a worker thread that runs the storage worker entry (see the Storage Worker recipe), waits until that thread has opened, tuned and migrated the database, and then connects the calling thread to it. From then on no thread but the database thread touches the database file; every other thread, the API thread and the monitor worker alike, uses the `Storage` port as a client over a `MessagePort`.

It exports:

- **the start function** (`startStorageThread`) — takes a database connection description and an `onExit` callback, and resolves to a storage thread handle.
- **the storage thread handle** (`StorageThread`) — a `storage` port for this thread and a `connect()` function that makes a new port for another thread.
- **three wire types** shared with the worker: `StorageWorkerData` (`{ db }`, the worker's start data), `StorageWorkerRequest` (`{ attach }`, a port to serve) and `StorageWorkerReply` (`{ ready: true }` or `{ ready: false, error }`).

The reason for the design is in the Storage Remote recipe: an embedded database connection runs statements on the calling thread and a lock wait blocks that thread, so a shared connection once froze the API event loop and caused an outage. Here the module's job is only spawn and attach policy; the queue and wire protocol live in the Storage Remote module, and the database work lives in the worker.

