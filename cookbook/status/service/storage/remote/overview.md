
The `Storage` port carried over a Node `MessagePort`, so the thread that owns the database can differ from the threads that use it. An embedded `file:` libSQL connection runs every statement synchronously on the calling thread, and a lock wait spins there for up to the busy timeout (5 seconds). When the API thread held its own connection, a read that met the monitor worker's write or WAL checkpoint froze the API event loop, `/health` timed out, and the supervisor restarted the container (the 2026-10-22 outage). Behind this transport the API thread only awaits a reply, and the database thread is the only one that blocks.

Two functions form the contract: `createStorageServer(storage)` runs on the database thread and answers calls from any number of ports through one queue, and `connectStorage(port)` runs on a user thread and returns a `Storage` whose every method is a request over the port. The code is driver-agnostic: it serves whatever `Storage` it is handed and never names libSQL.

