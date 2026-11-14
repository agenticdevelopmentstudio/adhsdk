
- **Null and empty input**: There are no optional inputs. A `timeout` of 0 MUST give a non-blocking check. A negative `timeout` is not guarded: the deadline is already past, so the call behaves as a non-blocking check.
- **Boundary values**: A `timeout` large enough to overflow the dispatch deadline is not guarded by the source. The worst case of `stop(_:)` is two graces (4 seconds) plus the time to send the signals.
- **Concurrent access**: The exit flag is lock-protected, so reading it from several threads is safe. Two threads blocked in `waitForExit(timeout:)` together are covered by the open question on `concurrent-waiters`. A call made after one wait has returned true is answered at once.
- **Error states**: A process that cannot be reaped makes `stop(_:)` return false rather than throw; the caller decides what to do with a process it could not end. A `process.terminate()` on a process that was never launched is not guarded.
- **Handler timing**: A handler installed after launch can miss an exit that already happened; this is why the creation precondition exists and why the watch must be built before `run()`.
- **Lost wake-ups**: The wait MUST NOT depend on the blocking wait-until-exit call, which can miss its wake-up on macOS 26.6.
- **Reuse**: One watch serves one process; the exit flag is never reset, so a watch is not reusable across processes.
- **Offline or disconnected state**: Not applicable — this type does no network access.

