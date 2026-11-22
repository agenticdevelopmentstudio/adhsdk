
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

