
Vectors 001 to 018 are traced to `storage-remote.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| storage-remote-001 | call-wire, value-roundtrip | Call a method with arguments including a `Date`, over a connected pair | The server receives the same values, and the result reaches the caller with the `Date` still a `Date` |
| storage-remote-002 | shape-walk, nested-dispatch | Call `telemetry.errors.<method>` on the stub | The nested store's method runs with its own `this` and its result returns |
| storage-remote-003 | error-flatten, error-rebuild | A method throws an `Error` with a `code` and a `cause` | The caller's rejection has the same message, and its `cause` has the same message and `code` |
| storage-remote-004 | single-queue | Two ports each issue calls whose handlers resolve out of order | The handlers run one at a time in arrival order across both ports |
| storage-remote-005 | unclonable-args | Call with a function among the arguments | Rejects with the clone error (the source also deletes the pending entry before rejecting) |
| storage-remote-006 | closed-port-client | The server side closes while a call is pending | The pending call rejects with `storage connection closed` |
| storage-remote-007 | queue-survives-errors | A call that throws, then a call that succeeds on the same port | The first rejects, the second resolves |
| storage-remote-008 | non-error-throw | A method throws the string `boom` | The caller receives an `Error` named `Error` with message `boom` |
| storage-remote-009 | slow-call-log | A call that takes 2,500 ms | With a fake clock that advances 2,500 ms across the call, one warning matching `/^\[storage\] slow call a\.b \d+ms$/` is logged for a method at path `a.b` (exactly `[storage] slow call a.b 2500ms`), and the reply is still delivered |
| storage-remote-010 | shape-handshake, shape-walk | `serve(port)` for a storage with a method `a`, a nested store `n` holding a method `b` and a number `c`, and a number `d` | The first message on the port is `{ shape: { a: true, n: { b: true } } }` |
| storage-remote-011 | stub-build | `connectStorage(port)` before the shape arrives, then after | The promise is pending until the shape arrives; the resolved `Storage` has no `then` property, so `await` does not treat it as a thenable, and its methods are plain functions |
| storage-remote-012 | reply-match | After the shape, a reply `{ id: 999, ok: true, value: 1 }` for an id that is not pending, while a real call is pending | The unknown reply is ignored, and the pending call still settles from its own reply |
| storage-remote-013 | unclonable-result | A store method that returns a function | The caller's call rejects with a `DataCloneError` instead of hanging, and the next call still runs |
| storage-remote-014 | closed-port-server | Two ports served; the first port closes | The server stops listening on the first port and later messages on it are not answered; the second port is still served |
| storage-remote-015 | connect-failure | The port closes before the shape message | `connectStorage` rejects with `storage connection closed` |
| storage-remote-016 | error-flatten, error-rebuild | A method throws an error with a `cause` chain of seven errors in all | The caller's rejection has five errors in its chain (the error and four causes); the deeper causes are dropped |
| storage-remote-017 | error-flatten | A method throws an error with the numeric `code` 5 | The caller's rejection has `code` `'5'`, a string |
| storage-remote-018 | driver-agnostic | The module's imports | Only the `Storage` type from `./ports` and `node:worker_threads` types are imported; no database driver is imported or named in code (comments aside) |
