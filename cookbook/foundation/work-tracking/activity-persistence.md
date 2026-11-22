---
id: c6cd4263-02fa-4284-98d5-7d89001ca4c4
title: "Activity Persistence"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The storage contract work tracking writes through: activity spans, idle intervals, crash recovery and pruning, plus the recovered-end rule."
platforms:
  - swift
  - macos
tags:
  - work-tracking
  - foundation
  - persistence
depends-on:
  - 92a9546a-eec1-47ed-8420-7db51e8d0261
related:
  - aa775836-5679-4a22-9ff3-b2bdcb09cc20
  - d525cc69-4d2c-4d17-a570-f71e8d5aa273
references: []
approved-by: ""
approved-date: ""
---

# Activity Persistence

## Overview

`ActivityPersistence` is the storage contract work tracking writes through, per its doc comment "Where work-tracking writes. The host implements it over its own database." It declares the operations on two kinds of record: activity spans ([adhsdk.ingredient.foundation.work-tracking.activity-span-dto](cookbook:92a9546a-eec1-47ed-8420-7db51e8d0261)), each one stretch of focus on a tracked app, and idle intervals, each one stretch with the user away. The same file declares three companions:

- `ActivitySpanClose`, the three outcomes of closing one span (`none`, `closed`, `deleted`), which conforming hosts use internally.
- `ActivityRecovery.recoveredEnd(startedAt:lastSeenAt:openIdleFrom:)`, the one pure rule for where a span left open by a crash ends.
- `WorkTrackingPersistence`, the full storage a `WorkTrackingController` runs against: `ActivityPersistence` plus `WorkTrackingSettingsStore` ([adhsdk.ingredient.foundation.work-tracking.work-tracking-prefs](cookbook:d525cc69-4d2c-4d17-a570-f71e8d5aa273)) plus `knownRepoRoots(activeSince:)`.

The file holds no storage of its own. Two hosts conform in the toolkit: `InMemoryActivityStore` (tests and previews) and `DaemonDatabase` (SQLite). The second source file, `ActivityPersistenceContract.swift`, is the executable form of this contract: `ActivityPersistenceContract.runAll` runs fourteen named checks against fresh stores and returns failure messages, "so a host can run them from its own XCTest target". This recipe specifies the contract those hosts meet and the suite that checks it.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a storage protocol and a pure function, not a visual component.

## States

Not applicable — this is a storage protocol and a pure function, not a visual component. A span's open and closed states and the single open idle interval are covered under Behavioral Requirements.

## Accessibility

Not applicable — this is a storage protocol and a pure function, not a visual component.

## Conformance Test Vectors

Instants below are offsets from `T = 2026-10-01T09:00:00Z`, as `ActivityPersistenceContract` writes them (`T+60` is one minute later). Vectors 001 to 014 are the checks `ActivityPersistenceContract.runAll` runs, which `testInMemoryStoreMeetsTheContract` (`ActivityPersistenceContractTests`) and `testSQLAdapterMeetsTheContract` (`ActivityPersistenceSQLTests`) run against each host. Vectors 015 to 018 are `testRecoveredEndRules`. Vectors 019 to 022 are the in-memory prune tests in `ActivityPersistenceContractTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| activity-persistence-001 | open-span, close-open-span, list-open | Open span `a` at `T`; close it at `T+60` (check "open then close") | `openActivitySpans()` is empty; `a.endedAt == T+60` |
| activity-persistence-002 | close-sub-second-deletes | Open `a` at `T`; close it at `T` (check "close under 1s") | `activitySpans(since: T-10, limit: 10)` is empty |
| activity-persistence-003 | retitle-span, touch-span | Open `a`; retitle to `new`; touch at `T+30` (check "retitle and touch") | The open span has `windowTitle == "new"` and `lastSeenAt == T+30` |
| activity-persistence-004 | open-idle-once, recover-closes-open-spans | Open `a`, touch at `T+120`, open idle at `T+60`, open idle at `T+30`, recover at `T+3600` (check "single open idle interval") | `a.endedAt == T+60`; the second idle open was ignored |
| activity-persistence-005 | close-idle | Open `a`, touch at `T+120`, open idle at `T+60`, close idle at `T+90`, recover at `T+3600` (check "closed idle interval") | `a.endedAt == T+120` |
| activity-persistence-006 | recover-closes-open-spans, recover-count, recover-never-at-now | Open `a`, touch at `T+120`, recover at `T+3600` (check "recovery with heartbeat") | Returns 1; `a.endedAt == T+120` |
| activity-persistence-007 | recover-sub-second-deletes | Open `a` with no heartbeat, recover at `T+3600` (check "recovery without heartbeat") | `a` is gone |
| activity-persistence-008 | recover-closes-idle-at-now | Open `a`, touch `T+120`, idle at `T+60`, recover at `T+3600`; then open `b` at `T+4000`, touch `T+4100`, idle at `T+4050`, recover at `T+5000` (check "recovery with idle") | `a.endedAt == T+60`; `b.endedAt == T+4050`, so the first recovery closed the idle interval |
| activity-persistence-009 | recovered-end-ignores-out-of-range-idle | Open `a`, touch `T+120`, idle at `T+300`, recover at `T+3600` (check "recovery ignores late idle") | `a.endedAt == T+120` |
| activity-persistence-010 | recover-leaves-closed, recover-count | Close `a` at `T+60`; open `b` at `T+100`, touch `T+200`; recover at `T+3600` (check "recovery leaves closed spans") | Returns 1; `a.endedAt == T+60` |
| activity-persistence-011 | recover-count, recover-sub-second-deletes | Open `short` at `T` with no heartbeat; open `long` at `T+100`, touch `T+200`; recover at `T+3600` (check "recovery does not count deleted spans") | Returns 1 |
| activity-persistence-012 | close-keeps-first-end | Close `a` at `T+60`, then at `T+120` (check "re-close keeps first close") | `a.endedAt == T+60` |
| activity-persistence-013 | open-duplicate-id-throws | Open `a` at `T`; open another `a` at `T+10` (check "duplicate id throws") | The second open throws; one span stored |
| activity-persistence-014 | list-since, list-order, list-limit | `mid` at `T+100` closed `T+160`; `live` at `T+200` open; `old` at `T` closed `T+60`; list since `T-10` with limit 10, then limit 2 (check "listing") | `["live", "mid", "old"]`, then `["live", "mid"]` |
| activity-persistence-015 | recovered-end-base-heartbeat | `recoveredEnd(startedAt: "2026-10-01T09:00:00Z", lastSeenAt: "2026-10-01T09:02:00Z", openIdleFrom: [])` | `"2026-10-01T09:02:00Z"` |
| activity-persistence-016 | recovered-end-base-start | `recoveredEnd(startedAt: "2026-10-01T09:00:00Z", lastSeenAt: "", openIdleFrom: [])` | `"2026-10-01T09:00:00Z"` |
| activity-persistence-017 | recovered-end-idle-pullback | Same start and heartbeat, `openIdleFrom: ["2026-10-01T09:01:00Z"]` | `"2026-10-01T09:01:00Z"` |
| activity-persistence-018 | recovered-end-ignores-out-of-range-idle | Same start and heartbeat, `openIdleFrom: ["2026-10-01T08:00:00Z"]` | `"2026-10-01T09:02:00Z"` |
| activity-persistence-019 | prune-derived-spans, prune-count | Closed `old` ended `2026-09-01T10:00:00Z`, closed `new` ended `2026-10-01T10:00:00Z`; prune before `2026-09-15T00:00:00Z` (`testInMemoryPruneRemovesSpansEndedBeforeCutoff`) | Returns 1; `["new"]` remains |
| activity-persistence-020 | prune-derived-spans | Same `old` span with `prunable` returning false (`testInMemoryPruneHonoursPrunable`) | Returns 0; `old` remains |
| activity-persistence-021 | prune-never-open | Open span started `2026-09-01T09:00:00Z`; prune before `2099-01-01T00:00:00Z` (`testInMemoryPruneNeverRemovesOpenSpans`) | Returns 0; the span remains |
| activity-persistence-022 | prune-idle, prune-count | Idle closed `2026-09-01T09:30:00Z` and idle open from `2026-10-01T09:00:00Z`; prune before `2026-09-15T00:00:00Z` (`testInMemoryPruneRemovesOnlyClosedOldIdleIntervals`) | Returns 1; one idle interval remains |
| activity-persistence-023 | known-roots-content, known-roots-no-blank | Billed root `/repo/billed`; sessions with roots `/repo/recent`, `/repo/edge` after the cutoff, `/repo/old` and `/repo/justout` before it, and one blank (`testKnownRepoRootsUnionsBillingReposAndSessionsSinceTheCutoff`) | Sorted result `["/repo/billed", "/repo/edge", "/repo/recent"]` |
| activity-persistence-024 | recovered-end-canonical | `recoveredEnd(startedAt: "2026-10-01T09:00:00.218Z", lastSeenAt: "", openIdleFrom: [])` | `"2026-10-01T09:00:00Z"` |
| activity-persistence-025 | contract-run-all, contract-empty-pass, contract-fresh-store | `ActivityPersistenceContract.runAll { InMemoryActivityStore() }` (`testInMemoryStoreMeetsTheContract`) | `[]` |
| activity-persistence-026 | contract-run-all, contract-empty-pass | `ActivityPersistenceContract.runAll { try makeDB() }` over a fresh `DaemonDatabase` (`testSQLAdapterMeetsTheContract`) | `[]` |
| activity-persistence-027 | contract-thrown-error, contract-failure-prefix | `runAll` with a `make` closure that always throws error `E` | Fourteen failures, each `<check name>: threw E`, in the check order of `contract-run-all` |
| activity-persistence-028 | contract-failure-prefix | A store whose `activitySpans` ignores `limit` | The result contains a failure starting `listing: limit not respected:` |
| activity-persistence-029 | prune-derived-spans, prune-count | Closed `derived` 09:00 to 10:00 and closed `pending` 11:00 to 12:00 on 2026-09-01, `prunable` accepts only `derived`; idle 09:15 to 09:30 and 11:15 to 11:30; prune before `2026-09-15T00:00:00Z` (`testInMemoryPruneKeepsIdleTimeAKeptSpanStillOverlaps`) | Returns 2; spans `["pending"]`; idle starts `["2026-09-01T11:15:00Z"]` |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `any ActivityPersistence` or `any WorkTrackingPersistence` | none | The host's database, injected into the recorder and the `WorkTrackingController` |
| derived (host rule) | host-defined | `prunable` accepts every span in `InMemoryActivityStore` | Which closed spans `pruneActivity` may delete |
| `endedBefore` | ISO-8601 UTC string | none | Prune cutoff, supplied by the caller |
| `activeSince` | ISO-8601 UTC string | none | Known-roots cutoff; the controller passes `knownRootsSessionDays` days ago |
| one-second floor | constant | 1 second | Spans shorter than this are deleted on close; not configurable |

No environment variables or settings keys are read by this contract.

## Deep Linking

Not applicable: the contract is storage with no URL or navigation surface.

## Localization

Not applicable: the contract holds no user-facing strings; the `ActivityPersistenceContract` failure messages are developer test output.

## Accessibility Options

Not applicable: the contract has no visual surface, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source declares no flag; whether work tracking runs is the `WorkTrackingPreferences.enabled` setting, read outside this contract.

## Analytics

Not applicable: the contract emits no events.

## Privacy

- **Data collected**: Spans carry `windowTitle`, `workingPath`, `repoRoot`, `branch` and `appName`, which describe what the user works on; idle intervals record when the user was away.
- **Storage**: The host's own database; in the toolkit, the `activity_span` and `activity_presence` tables of `DaemonDatabase`, or memory for `InMemoryActivityStore`.
- **Transmission**: The contract does no networking; data leaves the process only through the host's own channels, such as the work-tracking XPC protocol.
- **Retention**: `pruneActivity(endedBefore:)` deletes derived spans and old idle intervals; the caller chooses the cutoff, and a span the host has not derived is kept indefinitely.

## Logging

Not applicable: the protocol file contains no log calls. The `DaemonDatabase` host logs one `info` line, "recovery deleted sub-second span", with the span id, when recovery deletes a span.

## Platform Notes

- **SwiftUI**: Source platform. `ActivityPersistence.swift` (Core) declares the protocols, `ActivitySpanClose` and `ActivityRecovery`; `ActivityPersistenceContract.swift` beside it is the shared conformance suite. Hosts are `InMemoryActivityStore.swift` (Activity tier) and `DaemonDatabase+ActivityPersistence.swift` (Database tier). The protocol sits in Core so the session database, a tier below Activity, can conform to `WorkTrackingPersistence`. Swift-specific: `AnyObject, Sendable` constraints, `@discardableResult` on recovery and prune, and timestamps as `String` canonicalized through `UTCTimestamp`.
- **Compose**: Declare a Kotlin `interface ActivityPersistence` with `suspend` functions, backed by Room (`@Dao` with `@Insert(onConflict = OnConflictStrategy.ABORT)` for the duplicate-id throw) and `@Transaction` for recovery and prune. Make `recoveredEnd` a top-level pure function. Kotlin has no `Sendable`; thread safety comes from Room's own executors.
- **React/Web**: A TypeScript `interface ActivityPersistence` with `Promise`-returning methods over IndexedDB (or SQLite on Node through `better-sqlite3`, whose calls are synchronous). Use a single readwrite transaction across `activity_span` and `activity_presence` stores for recovery. Keep `recoveredEnd` a pure function over ISO strings; string comparison holds only if every writer emits the same fixed-width `Z` form.
- **AppKit / UIKit**: Same Swift protocol; no difference. A Core Data host would map spans to an entity with a unique constraint on `id` and run recovery in one `performAndWait` block on a background context.
- **WinUI 3**: Define a C# `interface IActivityPersistence` with synchronous methods that throw, or `Task`-returning ones if the host is async. Back it with `Microsoft.Data.Sqlite`: a `PRIMARY KEY` on `id` makes the duplicate open throw `SqliteException`, and recovery and prune each run inside one `SqliteTransaction`. Make `ActivityRecovery.RecoveredEnd` a `static` pure method; keep timestamps as fixed-width `yyyy-MM-ddTHH:mm:ssZ` strings with `string.CompareOrdinal`, or switch to `DateTimeOffset` throughout and drop the canonicalization. An in-memory test host uses `lock` around a `List<ActivitySpan>`. `ActivitySpanClose` becomes a C# `enum`, and `WorkTrackingPersistence` an interface inheriting `IActivityPersistence` and the settings-store interface.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/ActivityPersistence.swift` | confirmed (1.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/ActivityPersistenceContract.swift` | confirmed (1.1.0) |

## Design Decisions

**Decision**: A span shorter than one second is deleted on close instead of being kept.
**Rationale**: The protocol doc comment states it; a sub-second span carries no billable time. `DaemonDatabase` also deletes the open billing segment derived from that span, which nothing else would close (review F7).
**Approved**: pending

**Decision**: Recovery ends a crashed span at its last heartbeat, pulled back to an open idle start, and never at `now`.
**Rationale**: The `ActivityRecovery` doc comment: "Never later than the heartbeat — downtime is never billed." The time between a crash and the restart is not work.
**Approved**: pending

**Decision**: Recovery counts only spans it closed, not spans it deleted.
**Rationale**: A deleted span is not a recovered one (review F31); the count reports surviving spans.
**Approved**: pending

**Decision**: Re-closing a closed span keeps its first end, and opening a used id throws.
**Rationale**: An id is a span's identity, and the first close is the true end (review F33). The SQL host gets both from its primary key and its `AND ended_at = ''` guard; the in-memory host copies them.
**Approved**: pending

**Decision**: What prune may delete ("derived") is left to the host.
**Rationale**: The protocol says so, and `ActivityPersistenceContract` leaves prune out for that reason. The SQL host prunes only spans billing has derived, so it never loses unbilled time.
**Approved**: pending

**Decision**: Hosts keep an old idle interval that a kept span still overlaps, which the protocol doc comment does not mention.
**Rationale**: Re-deriving a kept span needs its idle time, and losing it would bill idle time (the comment on the `DaemonDatabase` prune). `prune-idle` states the rule both hosts follow.
**Approved**: pending

**Decision**: Idle intervals are written but not readable through the protocol.
**Rationale**: Only recovery consumes them inside the store; the conformance suite observes them through recovery instead.
**Approved**: pending

**Decision**: Timestamps are fixed-width ISO-8601 UTC strings compared as strings.
**Rationale**: `UTCTimestamp` is the one owner of the wire instant, and string order is chronological only while every writer produces the same width, so `recoveredEnd` canonicalizes before comparing.
**Approved**: pending

**Decision**: The conformance suite ships in Core beside the protocol and returns failure messages instead of asserting.
**Rationale**: Its doc comment: it returns messages "so a host can run them from its own XCTest target". The file imports only Foundation, so it ships in the framework rather than a test target, and each host (the Activity tier's in-memory store, the Database tier's `DaemonDatabase`) asserts the result is empty in its own test target.
**Approved**: pending

**Decision**: `close-outcomes` and `recover-atomic` are SHOULD, not MUST.
**Rationale**: `ActivitySpanClose` is not part of the public protocol signature and atomicity is not stated in the protocol; both hosts do both, but a host MAY reach the same observable result differently.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | reliability |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | partial | privacy-and-data |

The protocol keeps storage separate from every work-tracking rule, which stays in the controller (review F14), so separation of concerns passes. Unit coverage passes: `ActivityPersistenceContract` runs fourteen checks against both hosts, `testRecoveredEndRules` pins the recovery rule, and the prune and known-roots tests cover the host-specific operations. Every operation throws rather than failing silently. Data integrity is partial: duplicate ids are refused and re-close keeps the first end, but timestamps are unvalidated strings, and an unparseable one silently deletes a span as sub-second. State recovery passes: `recoverActivity` closes every open span and idle interval after a crash without billing downtime. Retention is partial because prune deletes only derived spans and the cutoff is the caller's, so an underived span is kept indefinitely, and the protocol doc comment omits the idle-overlap exception both hosts apply.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-21 | Mike Fullerton | Covers the conformance suite (ActivityPersistenceContract.swift): its requirements, vectors and edge cases; adds the overlapping-idle prune vector; drops the authored Reference Implementations section |
