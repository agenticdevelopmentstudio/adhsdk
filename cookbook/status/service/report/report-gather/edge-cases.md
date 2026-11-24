
- **Null and empty params** (MUST): null, undefined and `''` for `range`, `days`, `wait` or `logs` take the default; they are never an error.
- **Boundary params** (MUST): `days` 1 and 365 and `wait` 0 and 60 are accepted; 0 and 366, and -1 and 61, are rejected.
- **Param forms** (MUST): `'+5'`, `' 5'` and `'1e1'` are not digit strings and are rejected; `'007'` is accepted as 7. A numeric `logs` other than 0 or 1 is rejected.
- **Empty or whitespace log** (MUST): a log of only whitespace gives `{ tail: [], lines: 0 }`; a one-line log gives that line and `lines` 1. Trailing spaces on the last line are dropped too.
- **Source throws** (MUST): the read becomes a failed read with the error's message, or `String(err)` for a non-Error throw; no other read is affected.
- **Source hangs** (MUST): the deadline rejects after 20 seconds (dashboards: `wait` plus 20). The deadline does not cancel the underlying work, which may keep running after the report is returned; the code has no cancellation.
- **Dashboard still refreshing** (MUST): the second read is used even when settle returned false or timed out; the rules module records the note.
- **Dashboard settle throws** (MUST): the throw fails that dashboard read like any other source error.
- **Concurrent access**: the sources are read concurrently with `Promise.all` on single-threaded JavaScript, and the only shared promise is the monitor read, awaited by the deploy-log selection after the feed read. Each call to `gatherReport` is independent; the dashboards and integrations caches are shared with the routes and own their own ordering.
- **Failed or empty board** (MUST): with `logs` true and a monitor read that failed, or a board with no failing deploys, no log is read.
- **More than five failing deploys** (MUST): only the first five by the board's order have logs; the rest are listed without log fields.
- **Log source unavailable** (MUST): a missing deployment, a missing token, a provider error or a timeout is recorded as that deploy's `{ error }`; it never fails the report.
- **Storage unavailable**: a storage error inside a source read is the same as any thrown error and becomes a failed read.
- **Offline or disconnected state**: the module makes no network call itself; it awaits reads that do (providers, dashboards, log fetch). A disconnect during one of them surfaces as that source's error or its deadline, and the report is still built from the rest. With no scheduler, `lastCycleAt` comes from the stored probe, so a monitor running elsewhere is judged by data, not by liveness.

