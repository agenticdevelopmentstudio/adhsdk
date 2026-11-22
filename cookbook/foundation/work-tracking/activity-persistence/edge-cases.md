
- **Empty `lastSeenAt`**: Recovery MUST end the span at its start, which is under a second, so the span MUST be deleted (vector 007).
- **Heartbeat earlier than start**: `recoveredEnd` MUST return the heartbeat (canonicalized), since no idle start can lie between start and an earlier base; closing at that end measures zero seconds through `UTCTimestamp.seconds`, so the span MUST be deleted.
- **Unparseable timestamps**: `recoveredEnd` MUST compare the raw strings it could not canonicalize; `UTCTimestamp.seconds` reads an unparseable pair as zero, so a close with an unparseable `endedAt` or `startedAt` MUST delete the span as sub-second.
- **Idle start equal to start or to base end**: The bounds are inclusive, so an idle start equal to `startedAt` MUST be chosen, which then deletes the span as sub-second; one equal to the base end MUST be chosen and yields the base end.
- **Several open idle intervals**: The protocol allows at most one open interval through `openIdleInterval`, but `recoveredEnd` takes a list and MUST pick the earliest in range.
- **Unknown id for close, retitle or touch**: Each MUST be a no-op that does not throw.
- **Recovery with no open span**: `recoverActivity(now:)` MUST return 0 and change no span; it still closes an open idle interval at `now`.
- **`limit` of zero or negative**: `activitySpans(since:limit:)` MUST return an empty list; both hosts clamp with `max(0, limit)`.
- **Prune cutoff in the far future**: Open spans MUST survive (vector 021); a closed span the host does not count as derived MUST survive however old.
- **Storage failure**: Each operation MUST throw the host's error; the contract adds no retry. `WorkTrackingController.knownRoots` logs a failed `knownRepoRoots` read and retries on its next call, and the recorder reports failed writes to the controller's `noteWriteFailure`.
- **Concurrent access**: Conforming stores MUST be safe to call from several threads, as `Sendable` declares. `InMemoryActivityStore` serializes every call under one `NSLock`; `DaemonDatabase` is safe for concurrent use and wraps close, recovery and prune in transactions. The recorder calls in on its own serial queue, per the `DaemonDatabase` extension's doc comment.
- **Contract base instant does not parse**: `ActivityPersistenceContract` MUST stop with `preconditionFailure("cannot offset ...")` when `UTCTimestamp.adding` returns nil for its base; the base is the constant `2026-10-01T09:00:00Z`, so this cannot occur unless `UTCTimestamp` changes.
- **Contract `make` throws**: `runAll` MUST record the error as that check's failure and continue (vector 027), so one broken store factory yields fourteen failures, not a thrown `runAll`.
- **Offline, timeouts and cancellation**: Not applicable — the contract is local storage with no network, and no operation is async or cancellable.

