
**Shape**

- **status-cases**: `SessionStatus` MUST have exactly three cases: `active`, `stale` and `ended`.
- **status-raw-values**: Each case's `String` raw value MUST equal its case name: `"active"`, `"stale"`, `"ended"`.
- **status-sendable**: `SessionStatus` MUST conform to `Sendable`.
- **status-not-case-iterable**: `SessionStatus` MUST NOT conform to `CaseIterable`; the source declares only `String` and `Sendable`.
- **status-raw-init-optional**: Initializing from a raw string that is not one of the three values MUST yield no value (the failable `init(rawValue:)` returns `nil`).

**Meaning of each case, as the SDK uses them**

- **active-meaning**: `active` MUST mean a live process exists for the session. The liveness service promotes or resurrects a session to `active` when a live `claude` process maps to its id.
- **ended-meaning**: `ended` MUST mean no live process remains for the session. The liveness service sets it when the process is gone and the recorded `cwd` is not empty.
- **stale-declared**: `stale` is a declared case that nothing in the SDK's own daemon code writes. `LivenessService` sets only `active` and `ended`. The sessions table's status column allows it (`CHECK(status IN ('active','stale','ended'))`) and `fetchActiveSessionsForLiveness` selects rows whose status is `active` or `stale`, so a consumer MUST accept it. A `stale` row is not in the active set, so the liveness pass sets it `active` when a live process maps to it and `ended` when none does.
- **status-vs-activity**: A consumer that needs to know what a live session is doing MUST use `SessionActivity` and not infer it from `SessionStatus`.

**Use as a stored and published value**

- **status-stored-as-raw**: Code that writes or compares the status column MUST use the `rawValue` string, as `updateSessionStatus(_:sessionId:)` and the liveness comparison `status == SessionStatus.active.rawValue` do.
- **status-update-failure**: `updateSessionStatus(_:sessionId:)` MUST NOT throw; it writes the raw value with a single-row UPDATE and logs a failure through the logger.
- **status-published-as-raw**: A session-status broadcast MUST carry the raw string in the payload's `status` field (see the `SessionEventSink` recipe).

