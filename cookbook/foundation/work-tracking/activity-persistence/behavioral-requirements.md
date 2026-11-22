
### Shape of the contract

- **reference-and-sendable**: A conforming store MUST be a reference type that is `Sendable`, as the protocol's `AnyObject, Sendable` constraint declares, so one store instance can be shared across threads.
- **throwing-operations**: Every operation MUST be able to report a storage failure by throwing; the protocol marks every member `throws`.
- **utc-timestamps**: Every timestamp passed into or returned from the store MUST be an ISO-8601 UTC string in the `UTCTimestamp` wire form, as the protocol doc comment declares; the protocol takes `String`, so the caller owns this precondition.

### Spans

- **open-span**: `openActivitySpan(_:)` MUST store the given span with every field as supplied.
- **open-duplicate-id-throws**: `openActivitySpan(_:)` MUST throw when a span with the same `id` already exists, and MUST leave the stored span count unchanged.
- **close-open-span**: `closeActivitySpan(id:endedAt:)` MUST set `endedAt` on the span with that `id` when the span is open and the closed span lasts at least one second.
- **close-sub-second-deletes**: `closeActivitySpan(id:endedAt:)` MUST delete the span, not close it, when the whole seconds from its `startedAt` to `endedAt` are fewer than 1.
- **close-keeps-first-end**: Closing a span that is already closed MUST leave its first `endedAt` unchanged.
- **close-unknown-id**: Closing an `id` with no open span MUST NOT throw and MUST change nothing; both hosts return `ActivitySpanClose.none` internally.
- **close-outcomes**: A host's internal close step SHOULD report its outcome as `ActivitySpanClose` (`none` for no open span, `closed`, `deleted` for under a second) so recovery can count only `closed`; the public `closeActivitySpan` returns nothing, so a host MAY report it another way.
- **retitle-span**: `retitleActivitySpan(id:title:)` MUST set the span's `windowTitle` to `title`.
- **touch-span**: `touchActivitySpan(id:at:)` MUST set the span's `lastSeenAt` to `at`, recording that the span was still current then.
- **retitle-touch-any-span**: Retitle and touch MUST NOT check whether the span is open; both hosts update a closed span too, and an unknown `id` is a no-op that does not throw.

### Idle intervals

- **open-idle-once**: `openIdleInterval(from:)` MUST open an idle interval starting at `from` only when no idle interval is open; while one is open the call MUST change nothing.
- **close-idle**: `closeIdleInterval(until:)` MUST set the end of the open idle interval to `until`; with none open it MUST change nothing.
- **idle-not-readable**: The contract MUST NOT expose idle intervals for reading; they are observable only through their effect on recovery, as `ActivityPersistenceContract` states.

### Recovery

- **recover-closes-open-spans**: `recoverActivity(now:)` MUST close every open span at the end `ActivityRecovery.recoveredEnd` computes from that span's `startedAt`, `lastSeenAt` and the `from` of every open idle interval.
- **recover-never-at-now**: `recoverActivity(now:)` MUST NOT end a span at `now`; downtime is never billed.
- **recover-closes-idle-at-now**: `recoverActivity(now:)` MUST close every open idle interval at `now`.
- **recover-sub-second-deletes**: A span whose recovered end is less than one second after its start MUST be deleted, as `close-sub-second-deletes` requires.
- **recover-count**: `recoverActivity(now:)` MUST return the number of spans it closed, excluding spans it deleted for being under a second.
- **recover-leaves-closed**: `recoverActivity(now:)` MUST NOT change a span that was already closed.
- **recover-atomic**: The SQLite host MUST run the whole recovery in one transaction; the in-memory host runs it under one lock. Hosts SHOULD do the same, so a reader never sees half a recovery.

### The recovered-end rule

- **recovered-end-base-heartbeat**: `recoveredEnd` MUST use `lastSeenAt` as the base end when it is non-empty.
- **recovered-end-base-start**: `recoveredEnd` MUST use `startedAt` as the base end when `lastSeenAt` is empty.
- **recovered-end-idle-pullback**: `recoveredEnd` MUST return the earliest open idle start that is at or after `startedAt` and at or before the base end, when one exists. The `ActivityRecovery` doc comment speaks of an idle interval "that opened after that heartbeat", but the code and the contract check "recovery ignores late idle" both ignore an idle start later than the heartbeat.
- **recovered-end-ignores-out-of-range-idle**: `recoveredEnd` MUST ignore an idle start earlier than `startedAt` or later than the base end.
- **recovered-end-canonical**: `recoveredEnd` MUST canonicalize each input through `UTCTimestamp.canonical` before comparing, and MUST use an input unchanged when it does not parse.
- **recovered-end-string-order**: `recoveredEnd` MUST compare instants as strings, which is chronological only because every canonical instant has the same fixed width.
- **recovered-end-never-later**: The result MUST NOT be later than the base end.
- **recovered-end-pure**: `recoveredEnd` MUST be a pure function with no side effects.

### Pruning and reading

- **prune-derived-spans**: `pruneActivity(endedBefore:)` MUST delete only closed spans that ended before the cutoff and that the host counts as derived; what derived means is the host's (`billing_derived_at = ended_at` in `DaemonDatabase`, the `prunable` predicate in `InMemoryActivityStore`).
- **prune-never-open**: `pruneActivity(endedBefore:)` MUST NOT delete an open span, however old.
- **prune-idle**: `pruneActivity(endedBefore:)` MUST delete every closed idle interval that ended before the cutoff and that no span still kept after the span deletion overlaps (a span overlaps when it started before the interval's end and is open or ended after the interval's start); it MUST NOT delete an open idle interval. The protocol doc comment gives only the first half ("idle intervals that ended before it"); the overlap exception is declared by the `DaemonDatabase` prune's doc comment, mirrored in `InMemoryActivityStore`, and pinned in both hosts by `testInMemoryPruneKeepsIdleTimeAKeptSpanStillOverlaps` and `testPruneKeepsIdleTimeAKeptSpanStillOverlaps`.
- **prune-count**: `pruneActivity(endedBefore:)` MUST return the total rows deleted, spans and idle intervals together.
- **list-since**: `activitySpans(since:limit:)` MUST return every open span plus every closed span whose `endedAt` is at or after `since`.
- **list-order**: `activitySpans(since:limit:)` MUST order the result by `startedAt`, newest first.
- **list-limit**: `activitySpans(since:limit:)` MUST return at most `limit` spans, and none when `limit` is zero or negative.
- **list-open**: `openActivitySpans()` MUST return exactly the spans whose `endedAt` is empty, in no specified order.

### WorkTrackingPersistence

- **work-tracking-persistence-composition**: `WorkTrackingPersistence` MUST be `ActivityPersistence` plus `WorkTrackingSettingsStore` plus `knownRepoRoots(activeSince:)`; every work-tracking rule stays in the controller, not in the store (review F14).
- **known-roots-content**: `knownRepoRoots(activeSince:)` MUST return the project roots the host bills and the roots of sessions active at or after `cutoff`.
- **known-roots-no-blank**: `knownRepoRoots(activeSince:)` MUST leave out blank roots.
- **known-roots-order-free**: `knownRepoRoots(activeSince:)` MAY return roots in any order.

### The conformance suite

- **contract-run-all**: `ActivityPersistenceContract.runAll(_:)` MUST run the fourteen checks "open then close", "close under 1s", "retitle and touch", "single open idle interval", "closed idle interval", "recovery with heartbeat", "recovery without heartbeat", "recovery with idle", "recovery ignores late idle", "recovery leaves closed spans", "recovery does not count deleted spans", "re-close keeps first close", "duplicate id throws" and "listing", in that order.
- **contract-empty-pass**: `runAll` MUST return an empty array when the store passes every check.
- **contract-fresh-store**: `runAll` MUST call its `make` closure once per check, so each check runs against a store no other check has written.
- **contract-failure-prefix**: Each failure message `runAll` returns MUST be the check's name, then `: `, then the check's own message (for example `listing: limit not respected: ...`).
- **contract-thrown-error**: An error thrown by `make` or by the store during a check MUST be recorded as the failure `<name>: threw <error>`, and `runAll` MUST go on to run the remaining checks.
- **contract-excludes-prune**: The suite MUST NOT check `pruneActivity`, because "what 'derived' means is the host's".
- **contract-observes-idle-through-recovery**: The suite MUST observe idle intervals only through the span end that `recoverActivity` produces, since the protocol does not expose them.
- **contract-fixture**: Every check MUST build its instants as whole-second offsets from `2026-10-01T09:00:00Z` through `UTCTimestamp.adding`, and its spans with bundle id `com.apple.dt.Xcode`, app name `Xcode`, window title `t` and tz `UTC`.
- **contract-span-lookup**: A check that reads a span's end MUST find it through `activitySpans(since:limit:)` with `since` ten seconds before the base and a limit of 50.

