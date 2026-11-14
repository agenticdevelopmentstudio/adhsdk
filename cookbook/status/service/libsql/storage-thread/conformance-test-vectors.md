
The module has no unit test of its own. `storage-thread.int.test.ts` › "migrates, serves two ports, and carries driver errors intact" runs it under bare node through `storage-thread-driver.mjs` (start, a store call on `storage`, a second port from `connect()`, a duplicate-insert error, a monitor cycle, and an empty `exits` list); vectors 001, 009, 010, 011 and 013 are covered by it, and the rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sthread-001 | worker-data, single-worker, ready-resolves, handle-shape | start with `{ url: "file:status.db" }` and the worker answers `{ ready: true }` | one worker spawned with `workerData` of `{ db: { url: "file:status.db" } }`; resolves to `{ storage, connect }` (the integration test's start resolves and `exits` stays empty) |
| sthread-002 | ready-false-rejects | the worker answers `{ ready: false, error: "no such table" }` | rejects with `storage thread failed to start: no such table` |
| sthread-003 | early-error-rejects | the worker emits `error` with message `boom` before any message | rejects with that error |
| sthread-004 | failed-start-leaves-worker | after sthread-002 | the worker has not been terminated by the module |
| sthread-005 | on-exit-error, listeners-after-ready | after a successful start, the worker emits `error` with message `oom` | `onExit` called once with `storage thread crashed: oom` |
| sthread-006 | on-exit-exit | after a successful start, the worker exits with code 1 | `onExit` called with `storage thread exited (1)` |
| sthread-007 | on-exit-may-repeat | a crash that emits `error` then `exit` | `onExit` called twice, once per event |
| sthread-008 | listeners-after-ready | the worker answers `{ ready: false }` and then exits | `onExit` is not called for the failed start |
| sthread-009 | connect-new-channel, connect-sync | `connect()` twice | two distinct ports returned at once; two `{ attach }` requests posted, each transferring one port (the test makes two ports with `connect()` and a client on the second reads what the first wrote) |
| sthread-010 | connect-same-queue | two ports each send a call at the same time | the calls run one after the other on the database thread, in arrival order |
| sthread-011 | this-thread-port, storage-ready-on-hello | start resolves | `storage` exposes the store methods the worker listed, as functions |
| sthread-012 | calls-reject-after-death | the worker exits, then a call is made through `storage` | rejects with `storage connection closed` |
| sthread-013 | errors-keep-detail | a store method throws an error with `code` `SQLITE_CONSTRAINT` and a cause | the caller's error has the same `message`, `code` and `cause` (the test's duplicate insert reaches the caller with a message chain that `isUniqueViolation` recognises) |
| sthread-014 | entry-resolved-from-package | the module is loaded from source or from the built package | the worker entry is the built `storage-worker` file, not a path beside the source file |

