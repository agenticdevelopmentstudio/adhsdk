
- **Null and empty input — connection**: the module passes the connection to the worker as given; a connection with no `url` makes the worker throw at load, which the host sees as the worker's `error` event before any reply.
- **Boundary — repeated connects**: any number of ports may be attached; each adds a listener on the database thread but no new connection.
- **Boundary — double start**: calling the start function twice spawns two worker threads that each open the file; the module does not prevent it, and the host calls it once at boot (see the Design Decision on not guarding against a second start).
- **Malformed input — failed start**: a `{ ready: false }` reply rejects the start, and the module does not terminate the worker or attach an `onExit` listener afterwards.
- **Concurrent access**: calls from every attached port, and from this thread's own port, are serialised by one queue on the database thread, so a slow call holds up the rest; the slow-call log belongs to the worker (see Storage Worker, [adhsdk.ingredient.status.service.libsql.storage-worker](cookbook:020cc0f0-04e9-4d03-8796-76027fb1131f), `slow-call-warning`).
- **Cancellation and timeouts**: the start function takes no abort signal and has no timeout; a call through a port has none either, and an unanswered call stays pending until the port closes.
- **Error states — database thread death**: `onExit` fires; pending and later calls through every port reject with `storage connection closed`.
- **Error states — exit before ready**: see `#requirements/exit-before-ready-unhandled`; no `exit` listener is attached during the ready wait.
- **Offline**: not applicable — the database is a local file or a connection the worker owns; the module itself performs no network I/O.

