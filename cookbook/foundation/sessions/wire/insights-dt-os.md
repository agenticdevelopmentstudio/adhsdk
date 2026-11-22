---
id: fcbf09d9-5555-4278-9940-2be920de49d3
title: "Insights DTOs"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Codable, Sendable wire types for the session daemon's /insights/* and /visualization/graph endpoints: charts, daily metrics, cache misses, graph."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - wire
  - insights
depends-on: []
related:
  - 6a645c72-4525-4b96-9df4-85abecfacd27
references: []
approved-by: ""
approved-date: ""
---

# Insights DTOs

## Overview

Two files declare the wire types for the session daemon's usage endpoints, each in an extension of the `Sessions` namespace. `InsightsDTOs.swift` covers the `/insights/*` HTTP endpoints; `GraphSnapshotDTO.swift` covers the `/visualization/graph` endpoint. Both files state the same wire rule in their opening comment: "Snake-case JSON on the wire; camelCase Swift on this side." There are thirteen types, all `public struct`, all `Codable` and `Sendable`, each with immutable `let` fields and a public memberwise initializer that assigns its arguments and does nothing else:

| Type | File | Endpoint that returns it | Role |
|------|------|--------------------------|------|
| `InsightsSummaryDTO` | `InsightsDTOs.swift` | `/insights/summary` | Summary card values at the top of the Insights dashboard |
| `EventsPerDayDTO` | `InsightsDTOs.swift` | `/insights/events-per-day` (array) | One row of the events-per-day stacked bar chart |
| `ToolUsageDTO` | `InsightsDTOs.swift` | `/insights/tools` (array) | One row of the tool usage bar chart |
| `ProjectActivityDTO` | `InsightsDTOs.swift` | `/insights/projects` (array) | One row of the top-projects bar chart |
| `SessionsPerDayDTO` | `InsightsDTOs.swift` | `/insights/sessions-per-day` (array) | One row of the sessions-per-day line chart |
| `DailyMetricDTO` | `InsightsDTOs.swift` | `/insights/daily-metrics` (array) | One rolled-up daily statistic from the `daily_metric` table |
| `CacheMissCauseDTO` | `InsightsDTOs.swift` | nested in `CacheMissesDTO.causes` | One row of the cache-miss cause histogram |
| `CacheMissModelDTO` | `InsightsDTOs.swift` | nested in `CacheMissesDTO.models` | Cache-miss totals for one (model, TTL) pair |
| `SystemPromptDeltaDTO` | `InsightsDTOs.swift` | nested in `CacheMissesDTO.systemPromptDeltas` | How many characters the system prompt moved on a `system_prompt_changed` miss |
| `CacheMissesDTO` | `InsightsDTOs.swift` | `/insights/cache-misses` | What prompt-cache misses cost, and why they happened |
| `GraphSnapshotDTO` | `GraphSnapshotDTO.swift` | `/visualization/graph` | Full graph snapshot rendered by the Visualization window |
| `GraphNodeDTO` | `GraphSnapshotDTO.swift` | nested in `GraphSnapshotDTO.nodes` | One node in the force-directed graph |
| `GraphLinkDTO` | `GraphSnapshotDTO.swift` | nested in `GraphSnapshotDTO.links` | One edge between two nodes |

The types carry no logic. The values in them are computed by `DaemonDatabase` (`insightsSummary`, `eventsPerDay`, `toolUsage`, `projectActivity`, `sessionsPerDay`, `dailyMetrics`, `cacheMisses` and `graphSnapshot` in `Database/Daemon/Usage`) and served by `UsageRoutes`, which encodes each through `RouteResponse.json`, the snake_case wire encoder described in Route Response ([adhsdk.ingredient.foundation.routing.route-response](cookbook:6a645c72-4525-4b96-9df4-85abecfacd27)). This recipe specifies the shapes and the meaning the doc comments give each field, so a port of the daemon or of a client reads and writes the same JSON. The file comments still call these "the stenographer `/insights/*` HTTP endpoints" and "the stenographer `/visualization/graph` endpoint"; the routes are now the shared `UsageRoutes` set any session daemon mounts.

## Behavioral Requirements

**Common shape**

- **dto-codable**: Each of the thirteen types MUST be encodable to and decodable from JSON.
- **dto-sendable**: Each of the thirteen types MUST be safe to pass across concurrency domains (Swift `Sendable`).
- **dto-immutable**: Every field of every type MUST be read-only after construction.
- **dto-init-no-validation**: Each initializer MUST store its arguments unchanged; it performs no range or format check, so a negative count, an empty `day`, a `missRate` above 1, an unknown node `kind` or a link to a node id that does not exist is stored as given.
- **dto-no-io**: The types MUST perform no I/O, logging or side effect; they are values only.

**Wire keys**

- **wire-snake-case**: On the wire, every field name MUST appear in snake_case, derived from the camelCase Swift name (`activeSessionCount` is `active_session_count`, `estimatedCostUsd` is `estimated_cost_usd`, `ttlKnown` is `ttl_known`, `byType` is `by_type`, `systemPromptDeltas` is `system_prompt_deltas`); single-word names such as `nodes`, `kind`, `weight`, `source` and `value` are unchanged.
- **wire-keys-from-strategy**: The types MUST NOT declare custom coding keys; the snake_case names come from the encoder's and decoder's key strategy (`RouteResponse.makeJSONEncoder` sets `convertToSnakeCase`), so a client MUST decode with the matching snake_case-to-camelCase strategy.
- **wire-dictionary-keys-verbatim**: The keys inside `by_type` MUST be the event-type strings exactly as stored (`"PreToolUse"`, `"ai-title"`), not converted to snake_case; Foundation's key strategy applies to the struct's own fields, not to a `[String: Int]` dictionary's keys.
- **wire-optional-omitted**: When an optional field (`InsightsSummaryDTO.mostUsedTool` or `GraphNodeDTO.status`) is `nil`, the encoded object MUST omit its key (`most_used_tool`, `status`) rather than write `null`.
- **wire-optional-missing-decodes**: Decoding an `InsightsSummaryDTO` whose `most_used_tool` key is absent, or a `GraphNodeDTO` whose `status` key is absent, MUST succeed with that field `nil`.
- **wire-required-missing-fails**: Decoding any type MUST fail when a non-optional field's key is absent.

**InsightsSummaryDTO**

- **summary-fields**: `InsightsSummaryDTO` MUST carry `activeSessionCount: Int`, `totalEventCount: Int`, `mostUsedTool: String?` and `longestSessionMinutes: Int`.
- **summary-most-used-tool-optional**: `mostUsedTool` MUST be optional; the producer sets it to `nil` when no tool use has been recorded (`testInsightsSummaryWithEmptyDB`). It and `GraphNodeDTO.status` are the only optional fields among the thirteen types.

**Per-day chart rows**

- **events-per-day-fields**: `EventsPerDayDTO` MUST carry `day: String` and `byType: [String: Int]`.
- **events-per-day-by-type**: `byType` MUST map each event type present that day to its count; a type absent that day has no key (the doc comment: "maps each event type present that day to its count").
- **sessions-per-day-fields**: `SessionsPerDayDTO` MUST carry `day: String` and `newSessions: Int`.
- **day-format**: The `day` field of `EventsPerDayDTO`, `SessionsPerDayDTO` and `DailyMetricDTO` MUST be a `YYYY-MM-DD` string, as each declaration's comment states; for `DailyMetricDTO` the day is in UTC.

**Top-N rows**

- **tool-usage-fields**: `ToolUsageDTO` MUST carry `toolName: String` and `count: Int`, where `count` is the tool's `PreToolUse` event count (the doc comment: "Top-N tools by `PreToolUse` count").
- **project-activity-fields**: `ProjectActivityDTO` MUST carry `project: String`, `eventCount: Int` and `sessionCount: Int`.
- **project-name**: `project` MUST be the last path component of the events' `cwd`, the same heuristic the menu bar uses (the doc comment; `DaemonDatabase.lastPathComponent` drops one trailing `/` and takes the text after the last `/`).

**DailyMetricDTO**

- **daily-metric-fields**: `DailyMetricDTO` MUST carry `day: String`, `metric: String`, `dimension: String`, `count: Int` and `valueSum: Double`.
- **daily-metric-additive**: `count` and `valueSum` MUST be additive across days and dimensions, so a consumer MAY sum them over any set of rows.
- **daily-metric-average**: A consumer computing an average MUST compute it as `valueSum / count`.
- **daily-metric-value-sum-zero**: The producer MUST write `valueSum` 0 on every metric except `project`, where it MUST be the number of distinct sessions with events in that project on that day (`count` being the project's events), which `projectActivity` reads as the session count. Summed across days it counts a session once per day it ran. The doc comments on `DailyMetricDTO` and the `daily_metric` migration say the same.

**Cache misses**

- **cause-fields**: `CacheMissCauseDTO` MUST carry `cause: String` and `occurrences: Int`.
- **cause-opaque**: `cause` MUST be an open string, never a closed enumeration; a consumer MUST accept a cause it has never seen, because the set Anthropic emits in `prompt_cache.miss_causes` "grows without notice".
- **cause-not-a-partition**: A consumer MUST NOT treat the `occurrences` of `causes` as a partition of `CacheMissesDTO.misses`; the doc comment states the tallies sum to less than `misses`, not more.
- **model-fields**: `CacheMissModelDTO` MUST carry `model: String`, `ttl: String`, `ttlKnown: Bool`, `misses: Int`, `requests: Int`, `recacheTokens: Int` and `estimatedCostUsd: Double`.
- **model-ttl-values**: `ttl` MUST be `"5m"`, `"1h"`, another reported spelling, or `""` when the status line reported none.
- **model-ttl-known**: `ttlKnown` MUST be `true` only when `ttl` is a spelling the pricing table can price (`TranscriptPricing.isKnownTTL`, which accepts exactly `"1h"` and `"5m"`).
- **model-ttl-fallback**: When `ttlKnown` is `false`, the row's `estimatedCostUsd` MUST have been priced with the 1.25× write premium as a fallback (`testAnUnpricedTTLIsFlaggedRatherThanPassedOffAsAFiveMinuteWrite`: a `"30m"` row is flagged and priced at 1.25×).
- **delta-fields**: `SystemPromptDeltaDTO` MUST carry `chars: Int` (signed: positive grew, negative shrank) and `occurrences: Int`.
- **delta-per-tick**: `occurrences` MUST count ticks whose miss counter advanced while reporting that size, not misses; a consumer MUST NOT read it as a share of the `system_prompt_changed` cause count.
- **misses-fields**: `CacheMissesDTO` MUST carry `since`, `coverageStart` (both `String`), `misses`, `requests`, `recacheTokens` (`Int`), `missRate`, `estimatedCostUsd` (`Double`), `unattributedMisses`, `unattributedRequests`, `unattributedRecacheTokens` (`Int`), `causes: [CacheMissCauseDTO]`, `models: [CacheMissModelDTO]` and `systemPromptDeltas: [SystemPromptDeltaDTO]`.
- **misses-since-echo**: `since` MUST echo the lower bound actually applied, with `""` meaning the whole history.
- **misses-coverage-start**: `coverageStart` MUST be the timestamp of the oldest status-line tick still on disk, or `""` when there is none.
- **misses-coverage-narrowed**: A consumer MUST read a `coverageStart` later than `since` as "the totals begin at `coverageStart`", because retention deletes old ticks and no rollup stands behind this report.
- **misses-rate**: `missRate` MUST equal `misses / requests`, or `0` when `requests` is `0`.
- **misses-unattributed-in-totals**: `misses`, `requests` and `recacheTokens` MUST include the unattributed shares; `unattributedMisses`, `unattributedRequests` and `unattributedRecacheTokens` are each a subset of the matching total.
- **misses-cost-floor**: `estimatedCostUsd` MUST exclude the unattributed recache tokens, so it is a floor on real spend; a consumer MUST NOT present it as a full estimate.
- **misses-models-order**: `models` MUST hold attributable (model, TTL) groups only, highest `recacheTokens` first, at most the caller's `limit` entries.
- **misses-totals-whole**: The totals MUST be summed over every group, including groups dropped from `models` by the `limit`, so they stay whole when the list is truncated.
- **misses-counted-as-increases**: Every count MUST be a sum of observed increases between consecutive ticks of one session, never a count of rows that mention a miss.
- **misses-first-tick-ignored**: The first tick of a session MUST contribute nothing to any count (`testCacheMissesIgnoresTheFirstTicksInheritedCounters`).

**Graph snapshot**

- **graph-fields**: `GraphSnapshotDTO` MUST carry `nodes: [GraphNodeDTO]` and `links: [GraphLinkDTO]`.
- **node-fields**: `GraphNodeDTO` MUST carry `id: String`, `kind: String`, `label: String`, `status: String?` and `weight: Int`.
- **node-kind-values**: `kind` MUST be one of `"session"`, `"tool"` or `"project"` (the doc comment); it is a plain string on the wire, not an enumeration, and the producer emits only those three.
- **node-id-namespaced**: `id` MUST be the node's kind, a colon and its key (`session:<session id>`, `tool:<tool name>`, `project:<project name>`), so a session and a tool with the same text cannot collide (the doc comment: "Namespaced by kind ... so a session and a tool cannot collide").
- **node-id-opaque**: A consumer MUST treat `id` as an opaque identifier ("Opaque identifier used by the JS renderer"), used only to match link endpoints to nodes.
- **node-label**: `label` MUST be the short text drawn on the node; the producer uses the first 8 characters of the session id for a session, the tool name for a tool and the project name for a project.
- **node-status-session**: For a session node, `status` MUST be the session's stored status; the doc comment names `"active"`, `"idle"` and `"ended"`, and the producer passes the `sessions.status` column through unchanged (`""` when that column is null).
- **node-status-nil**: For a tool or project node, `status` MUST be `nil`, so the key is omitted on the wire.
- **node-weight**: `weight` MUST be a size hint: the session's Claude event count for a session (`0` when it has none), the tool's total `PreToolUse` uses across the included sessions for a tool, and the number of included sessions in that project for a project.
- **link-fields**: `GraphLinkDTO` MUST carry `source: String`, `target: String` and `value: Int`.
- **link-endpoints**: `source` and `target` MUST be node `id` values; the producer emits only session-to-tool and session-to-project links, with the session as `source`.
- **link-value**: `value` MUST be the number of uses for a session-to-tool link and `1` for a session-to-project link.
- **graph-referential**: Every link the producer emits MUST name a `source` and a `target` present in the same snapshot's `nodes`; the types do not check this, so a hand-built snapshot can break it (`dto-init-no-validation`).
- **graph-session-limit**: The snapshot MUST include at most `limit` sessions, newest `last_activity_at` first, where `graphSnapshot` clamps `limit` to 1 through 200 and the route passes `?limit=` with a default of 100 and a ceiling of 1000 before that clamp.
- **graph-tool-source**: Tool nodes and session-to-tool links MUST come only from `PreToolUse` events with a non-empty tool name in the included sessions.
- **graph-project-skipped**: A session whose `cwd` has an empty last path component or a last path component of `"/"` MUST get no project node and no session-to-project link.
- **graph-node-order**: `nodes` MUST list every session node first, in the session order above, followed by the tool nodes and then the project nodes; the order within tool nodes, within project nodes and within `links` is unspecified, and a consumer MUST NOT depend on it.
- **graph-empty**: When no session is selected, the snapshot MUST be `nodes == []` and `links == []`.

## Appearance

Not applicable — this is a set of wire data types, not a visual component.

## States

Not applicable — this is a set of wire data types, not a visual component. The types hold no runtime state; each is an immutable value.

## Accessibility

Not applicable — this is a set of wire data types, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| insights-dtos-001 | wire-snake-case, summary-fields | Encode `InsightsSummaryDTO(activeSessionCount: 1, totalEventCount: 3, mostUsedTool: "Edit", longestSessionMinutes: 42)` with the wire encoder | JSON with keys `active_session_count`, `longest_session_minutes`, `most_used_tool`, `total_event_count` and values `1`, `42`, `"Edit"`, `3` |
| insights-dtos-002 | wire-optional-omitted | Encode `InsightsSummaryDTO(activeSessionCount: 0, totalEventCount: 0, mostUsedTool: nil, longestSessionMinutes: 0)` | JSON has no `most_used_tool` key; the other three keys are present with `0` |
| insights-dtos-003 | wire-optional-missing-decodes, wire-keys-from-strategy | Decode `{"active_session_count":0,"total_event_count":0,"longest_session_minutes":0}` with a snake_case-to-camelCase decoder | Succeeds; `mostUsedTool == nil` |
| insights-dtos-004 | wire-required-missing-fails | Decode `{"day":"2026-04-12"}` as `EventsPerDayDTO` | Decoding fails: `by_type` is missing |
| insights-dtos-005 | wire-dictionary-keys-verbatim, events-per-day-by-type | Encode `EventsPerDayDTO(day: "2026-04-12", byType: ["PreToolUse": 3, "SessionStart": 2, "ai-title": 1])` | `{"by_type":{"PreToolUse":3,"SessionStart":2,"ai-title":1},"day":"2026-04-12"}` (sorted keys); decoding it back yields the same three keys |
| insights-dtos-006 | events-per-day-by-type, day-format | `testEventsPerDayBucketsByDateAndType`: events on 2026-04-10 (two `PreToolUse`, one `PostToolUse`) and 2026-04-11 (one `PreToolUse`) | Two rows; `rows[0].day == "2026-04-10"`, `byType["PreToolUse"] == 2`, `byType["PostToolUse"] == 1`; `rows[1].byType["PreToolUse"] == 1` |
| insights-dtos-007 | summary-most-used-tool-optional | `testInsightsSummaryWithEmptyDB`: an empty database | `activeSessionCount == 0`, `totalEventCount == 0`, `mostUsedTool == nil`, `longestSessionMinutes == 0` |
| insights-dtos-008 | tool-usage-fields | `testToolUsageCountsPreToolUse`: two `Edit` and one `Read` `PreToolUse` events | First row `toolName == "Edit"`, `count == 2`; last row `toolName == "Read"`, `count == 1` |
| insights-dtos-009 | project-name, project-activity-fields | `testProjectActivityExtractsLastPathComponent`: two events under a `cwd` ending `project-a` in one session, one under `project-b` | `project-a` has `eventCount == 2`, `sessionCount == 1`; `project-b` has `eventCount == 1` |
| insights-dtos-010 | sessions-per-day-fields | `testSessionsPerDayCountsSessionStartOnly`: two sessions starting 2026-04-10, one on 2026-04-11 | Rows `("2026-04-10", 2)` and `("2026-04-11", 1)` for `(day, newSessions)` |
| insights-dtos-011 | daily-metric-fields, daily-metric-additive, daily-metric-value-sum-zero | `testRecomputeEmitsProjectMetric`: two events in one project on one day across two sessions | The `project` row for that day has `count == 2`, `valueSum == 2` |
| insights-dtos-012 | misses-rate, misses-fields | `testCacheMissesOnEmptyDBIsZero`: no status-line ticks | `misses == 0`, `requests == 0`, `missRate == 0`, `estimatedCostUsd == 0`, `causes`, `models` empty |
| insights-dtos-013 | misses-first-tick-ignored | `testCacheMissesIgnoresTheFirstTicksInheritedCounters`: one session with a single tick that already reports misses | `misses == 0`, `requests == 0`, `recacheTokens == 0` |
| insights-dtos-014 | misses-counted-as-increases, cause-fields | `testCacheMissesCountsIncreasesNotTicks`: a session whose counters advance once by one miss, ten requests and 100,000 recache tokens, re-rendered on later ticks | `misses == 1`, `requests == 10`, `recacheTokens == 100000`, `causes` is one row `("ttl_expired_1h", 1)` |
| insights-dtos-015 | misses-rate, model-fields, misses-cost-floor | `testCacheMissesPricesPerModelAndTTL`: one 1h miss of 1,000,000 tokens on `claude-opus-5`, one 5m miss of 1,000,000 tokens on `claude-fable-5-1`, ten requests each | `misses == 2`, `requests == 20`, `missRate == 0.1`, `estimatedCostUsd == 22.50`; the opus row costs `10.00`, the fable row `12.50` |
| insights-dtos-016 | model-ttl-known, model-ttl-fallback, model-ttl-values | `testAnUnpricedTTLIsFlaggedRatherThanPassedOffAsAFiveMinuteWrite`: a miss reported under TTL `"30m"` | The model row has `ttl == "30m"`, `ttlKnown == false`, `estimatedCostUsd == 6.25` |
| insights-dtos-017 | model-ttl-known | `testAKnownTTLIsNotFlagged`: a miss under a known TTL | `models.first.ttlKnown == true` |
| insights-dtos-018 | delta-fields, delta-per-tick | `testCacheMissesReportsOscillatingSystemPromptDeltas`: ticks reporting `+53` twice and `-53` once | `systemPromptDeltas.first == (53, 2)`; the `-53` row has `occurrences == 1` |
| insights-dtos-019 | misses-since-echo | `testCacheMissesFiltersBySince`: `since: "2026-04-15T00:00:00Z"` | `since == "2026-04-15T00:00:00Z"`; only the later miss is counted (`misses == 1`) |
| insights-dtos-020 | misses-coverage-start | `testCoverageStartIsEmptyWhenNoTickSurvives`: no ticks | `coverageStart == ""` |
| insights-dtos-021 | misses-coverage-narrowed | `testCoverageStartExposesAWindowWiderThanTheHistoryLeft`: ticks from 2026-04-10, `since: "2026-01-01T00:00:00Z"` | `since == "2026-01-01T00:00:00Z"` and `coverageStart > since` |
| insights-dtos-022 | dto-init-no-validation | `ToolUsageDTO(toolName: "", count: -1)` | Constructs; `toolName == ""`, `count == -1` |
| insights-dtos-023 | dto-sendable, dto-immutable | Pass a `CacheMissesDTO` into a detached task and attempt to assign `misses` | Passing compiles without a `Sendable` diagnostic; the assignment does not compile |
| insights-dtos-024 | cause-opaque | Decode `{"cause":"some_future_cause","occurrences":4}` as `CacheMissCauseDTO` | Succeeds; `cause == "some_future_cause"` |
| insights-dtos-025 | misses-unattributed-in-totals, misses-totals-whole, misses-models-order | `testCacheMissesReadsStatusLineAttrsAcrossAResetAndACauseObject`: one model, one TTL, no straddling deltas | `unattributedMisses == 0`, `models.map(\.model) == ["claude-opus-5"]`, `models.first.ttl == "1h"`, `misses == 3` |
| insights-dtos-026 | graph-fields, node-fields, link-fields, wire-snake-case | Encode `GraphSnapshotDTO(nodes: [GraphNodeDTO(id: "session:abc", kind: "session", label: "abc", status: "active", weight: 5)], links: [GraphLinkDTO(source: "session:abc", target: "tool:Edit", value: 3)])` with sorted keys | `{"links":[{"source":"session:abc","target":"tool:Edit","value":3}],"nodes":[{"id":"session:abc","kind":"session","label":"abc","status":"active","weight":5}]}` |
| insights-dtos-027 | wire-optional-omitted, node-status-nil | Encode `GraphNodeDTO(id: "tool:Edit", kind: "tool", label: "Edit", status: nil, weight: 2)` | JSON has keys `id`, `kind`, `label`, `weight` and no `status` key |
| insights-dtos-028 | wire-optional-missing-decodes | Decode `{"id":"project:adk","kind":"project","label":"adk","weight":1}` as `GraphNodeDTO` | Succeeds; `status == nil`, `weight == 1` |
| insights-dtos-029 | wire-required-missing-fails | Decode `{"source":"session:a","target":"tool:Edit"}` as `GraphLinkDTO` | Decoding fails: `value` is missing |
| insights-dtos-030 | graph-empty | `graphSnapshot` over a store with no sessions | `nodes == []`, `links == []` |
| insights-dtos-031 | node-id-namespaced, node-label, node-weight, node-status-session, graph-node-order | One session `0123456789abcdef` with status `"idle"`, `cwd` `/Users/me/adk`, and 4 Claude events of which 2 are `PreToolUse` `Edit` and 1 is `PreToolUse` `Read` | `nodes[0]` is `("session:0123456789abcdef", "session", "01234567", "idle", 4)`; tool nodes `("tool:Edit", weight 2)` and `("tool:Read", weight 1)` with `status == nil`; one project node `("project:adk", "adk", weight 1)` |
| insights-dtos-032 | link-endpoints, link-value, graph-referential, graph-tool-source | The store of vector 031 | Three links: `session:0123456789abcdef` to `tool:Edit` with `value == 2`, to `tool:Read` with `value == 1`, to `project:adk` with `value == 1`; every `source` and `target` is an `id` in `nodes` |
| insights-dtos-033 | node-weight, link-value | Two sessions in the same `cwd` `/w/proj`, each with one `PreToolUse` `Edit` | Tool node `tool:Edit` has `weight == 2`; project node `project:proj` has `weight == 2`; each session has its own session-to-tool link with `value == 1` |
| insights-dtos-034 | graph-project-skipped | One session with `cwd` `""` | One session node, no project node, no session-to-project link |
| insights-dtos-035 | graph-session-limit | 250 sessions; `graphSnapshot(limit: 1000)`, then `graphSnapshot(limit: 0)` | 200 session nodes, the 200 with the newest `last_activity_at`; then 1 session node, the newest |
| insights-dtos-036 | graph-tool-source | One session with a `PreToolUse` event whose tool name is `""` and a `PostToolUse` `Edit` event | No tool node and no session-to-tool link; the session node's `weight == 2` |
| insights-dtos-037 | node-kind-values, dto-init-no-validation | `GraphNodeDTO(id: "x", kind: "agent", label: "", status: nil, weight: -1)` | Constructs and encodes with `kind == "agent"`, `weight == -1` |
| insights-dtos-038 | daily-metric-value-sum-zero | `testRecomputeWritesValueSumOnlyOnProjectRows`: on one day, sessions `s1` (two events) and `s2` (one event) in `proj-a` and `s3` (one event) in `proj-b`, then recompute that day | Every non-`project` row has `valueSum == 0`; `proj-a` has `count == 3`, `valueSum == 2`; `proj-b` has `valueSum == 1` |

Vectors 006 through 021, 025 and 038 are asserted in `InsightsQueriesTests` against the producers; 001 to 005, 022 to 024, 026 to 029 and 037 are encoding and construction checks a port's unit tests can run on the types directly. Vectors 030 to 036 are derived from `DaemonDatabase.graphSnapshot` and the event-count queries it calls (`claudeEventCounts`, `claudeToolUseCounts`); no test in the source asserts them. `dto-no-io` has no vector: an absence of side effects is checked by reading the type, not by a test. `node-id-opaque` has no vector: it constrains consumers, not the types or the producer.

## Edge Cases

- **Nil tool**: `mostUsedTool == nil` MUST encode with the key omitted and decode back to `nil` (vectors 002, 003).
- **Nil node status**: `GraphNodeDTO.status == nil` MUST encode with the key omitted and decode back to `nil` (vectors 027, 028).
- **Missing required key**: Decoding MUST fail on a missing non-optional key; the types have no defaults (vectors 004, 029).
- **Unknown extra keys**: Decoding MUST ignore keys the type does not declare, which is the default behavior of synthesized decoding.
- **Empty collections**: `byType == [:]`, `causes == []`, `models == []`, `systemPromptDeltas == []`, `nodes == []` and `links == []` MUST encode as `{}` or `[]` and decode back; the empty `CacheMissesDTO` the producer returns for no store or an unparseable `since` has all three arrays empty and every number `0`, and the empty `GraphSnapshotDTO` has both arrays empty (vector 030).
- **Empty strings as sentinels**: `CacheMissesDTO.since == ""` MUST mean the whole history, `coverageStart == ""` MUST mean no tick on disk, and `CacheMissModelDTO.ttl == ""` MUST mean the TTL was unreported. They are strings, not optionals, so a port MUST keep the empty-string sentinel rather than map it to `null`.
- **Session with a null status**: A session node MUST carry `status == ""`, not `nil`, when the stored `sessions.status` is null, because the producer reads the column with a `""` default; a consumer SHOULD treat `""` as an unknown status, since the doc comment names only `"active"`, `"idle"` and `"ended"`.
- **Session with no events or no project**: A session node MUST still appear with `weight == 0` when the event store holds no Claude events for it, and with no project link when its `cwd` yields an empty or `"/"` component (vector 034).
- **Division by zero**: `missRate` MUST be `0`, never `NaN`, when `requests == 0` (vector 012).
- **Boundary values**: Counts are `Int` and costs `Double`; the initializers MUST NOT clamp or reject negative or out-of-range values (vectors 022, 037). The producers' `limit` is clamped to 1 to 100 before `models`, `causes` and `systemPromptDeltas` are filled, so each list holds at most 100 entries from `/insights/cache-misses`; `graphSnapshot` clamps its `limit` to 1 to 200 sessions, so a `?limit=` above 200 MUST yield at most 200 session nodes (vector 035).
- **Truncated list**: When `models` is cut at `limit`, the totals MUST still cover every group (`misses-totals-whole`).
- **Cause histogram short of total**: `causes` MUST be allowed to sum to less than `misses`; a cause first seen on a session's first tick is not counted.
- **Malformed `day`**: The types MUST store any `day` string unchanged; the `YYYY-MM-DD` format is a producer guarantee, not a decode check.
- **Dangling link or unknown kind**: The graph types MUST accept a link whose endpoint matches no node and a `kind` outside the three named values; referential integrity and the kind set are producer guarantees (`graph-referential`, `node-kind-values`), so a consumer rendering a decoded snapshot SHOULD skip a link whose endpoint it cannot find rather than fail, because nothing in the types prevents one.
- **Unstable order**: Tool nodes, project nodes and links MUST be allowed to arrive in a different order on each call with the same data; the producer builds them from unordered dictionaries.
- **Concurrent access**: Not applicable as a hazard: every type is an immutable `Sendable` value, so concurrent reads are safe and there is nothing to write.
- **Errors and offline**: Not applicable: the types do no I/O and throw only what the JSON decoder throws on malformed input; database failures belong to the producers (`graphSnapshot` rethrows, and `UsageRoutes` answers with `.failure`) and network failures to the client.

## Configuration

Not applicable to the types: they take no parameters, defaults, environment variables or injected dependencies beyond their memberwise initializer arguments. The wire key strategy is the caller's: `RouteResponse.makeJSONEncoder` on the server side, a snake_case-to-camelCase decoder on the client side. The caller-supplied bounds that shape their contents are the route's query parameters: `since` on every `/insights/*` endpoint (an unparseable value is a 400), the `metric`, `dimension`, `from` and `to` filters of `/insights/daily-metrics`, and `limit`. `/insights/*` reads `?limit=` with a default of 20 and a ceiling of 100 (`/insights/daily-metrics`: 1000 and 10,000), and `/visualization/graph` reads it with a default of 100 and a ceiling of 1000, which `graphSnapshot` then clamps to 1 through 200 sessions.

## Deep Linking

Not applicable: the types are data values and define no URLs; the `/insights/*` and `/visualization/graph` paths belong to `UsageRoutes`.

## Localization

Not applicable: the types hold no user-facing strings; `cause`, `metric`, `ttl`, `kind`, `status` and event-type keys are machine identifiers, and a node `label` is a session-id prefix, tool name or project name taken from the data, never translated text. Display text is the consuming view's job.

## Accessibility Options

Not applicable: the types are not visual, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the types emit no events; they carry aggregated usage counts the daemon computed, and sending them anywhere is the route's and client's business.

## Privacy

- **Data collected**: The types collect nothing themselves. Their values include tool names, project names (the last path component of a working directory), model names and, in graph session nodes, Claude Code session ids from local sessions.
- **Storage**: None; the types are transient values.
- **Transmission**: They are serialized onto the daemon's local HTTP responses by `UsageRoutes`; the types add no transport of their own.
- **Retention**: Not applicable to the types; retention of the underlying events is the daemon's (the `CacheMissesDTO.coverageStart` doc comment notes retention is opt-in and off by default).

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

The `platforms` of this recipe are swift and macos; the notes for the other targets are porting guidance only.

- **SwiftUI**: `Core/Sessions/Wire/InsightsDTOs.swift` and `Core/Sessions/Wire/GraphSnapshotDTO.swift` are Foundation-only and add the thirteen structs to the `Sessions` namespace enum. A SwiftUI Charts view consumes the insights arrays directly; `EventsPerDayDTO.byType` flattens into one `BarMark` per (day, type) for the stacked chart. The graph is drawn by a JavaScript force simulation ("Opaque identifier used by the JS renderer"), so a SwiftUI client typically hands the encoded snapshot to a `WKWebView`; a native rendering would lay out nodes in a `Canvas`. The types are not `Identifiable` or `Equatable`, so a `ForEach` needs an explicit `id:` key path such as `\.day`, `\.toolName` or `\.id`.
- **Compose**: Port each struct as a Kotlin `@Serializable data class` with `val` fields, and configure `Json { namingStrategy = JsonNamingStrategy.SnakeCase; ignoreUnknownKeys = true; explicitNulls = false }` so field names match and a `null` `mostUsedTool` or `status` is omitted. `byType` is `Map<String, Int>`; kotlinx.serialization does not rename map keys, which matches the source. Keep `kind` a `String` rather than an `enum class` if decoding must accept values beyond the three named ones.
- **React/Web**: Declare TypeScript interfaces with the snake_case wire names (`active_session_count`, `by_type: Record<string, number>`, `most_used_tool?: string`, `status?: string`) or map them to camelCase at the fetch boundary; do not run a generic key-camelizer over the whole response, because it would rewrite the `by_type` event-type keys that the source leaves verbatim. The graph's `nodes`/`links` with `source`, `target` and `value` are the shape d3-force's `forceLink` expects, keyed by `id`; note that d3 replaces `source` and `target` strings with node objects in place, so clone the snapshot before handing it over if the original is needed.
- **AppKit / UIKit**: The same Foundation structs are used unchanged; decode with `JSONDecoder` and `keyDecodingStrategy = .convertFromSnakeCase`, the counterpart of `RouteResponse.makeJSONEncoder`.
- **WinUI 3**: Port as C# `public sealed record` types with `init`-only properties (`public required int ActiveSessionCount { get; init; }`), giving the immutable values the source has. Serialize with `System.Text.Json` using `JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower, DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull }` (.NET 8 and later), so `MostUsedTool` and `GraphNodeDto.Status` (`string?`) are omitted when null; leave `DictionaryKeyPolicy` unset so `ByType` (`Dictionary<string, int>`) keys stay verbatim, matching the source. Mark the non-optional properties `required` so a missing key fails deserialization as Swift's decoder does, and keep `Kind` a `string` rather than a C# `enum` so an unknown value still deserializes. Records are immutable and safe to share across threads, so no locking is needed. For a dashboard, load the arrays into an `ObservableCollection<T>` on a view model that implements `INotifyPropertyChanged`, fetch them with `HttpClient.GetFromJsonAsync<T>` inside an `async Task`, and bind a chart control (for example a WinUI Community Toolkit or LiveCharts series) to the collection with `x:Bind`. For the graph, either host the same JavaScript renderer in a `WebView2` and pass the snapshot JSON through `CoreWebView2.PostWebMessageAsJson`, or draw it natively on a `Microsoft.UI.Xaml.Controls.Canvas` (or Win2D `CanvasControl`) with a force layout computed off the UI thread in a `Task`, building a `Dictionary<string, GraphNodeDto>` by `Id` to resolve each link's endpoints and skipping a link whose endpoint is missing.

<!-- No `## Reference Implementations` section is authored. Record the code that implements this
ingredient with `cookr implements <uuid|rdid> <location> --platform <p>` and `cookr confirm <uuid|rdid>`;
a compiled doc or skill shows those rows as a derived section here. -->

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/InsightsDTOs.swift` | confirmed (1.1.1) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/GraphSnapshotDTO.swift` | confirmed (1.1.1) |

## Design Decisions

**Decision**: Wire names come from the encoder's snake_case key strategy, not from per-type coding keys.
**Rationale**: Both file comments say "Snake-case JSON on the wire; camelCase Swift on this side", none of the thirteen types declares `CodingKeys`, and `RouteResponse.makeJSONEncoder` sets `convertToSnakeCase` for every route. One strategy keeps every field's name derivable; the cost is that a client decoding without the matching strategy fails on every multi-word key.
**Approved**: pending

**Decision**: `CacheMissCauseDTO.cause` is an open string rather than an enum.
**Rationale**: The doc comment: the set of causes "grows without notice, which is why it is stored opaquely ... and reported here as whatever was observed rather than as a fixed enum".
**Approved**: pending

**Decision**: Unattributed misses are counted in the totals but never priced.
**Rationale**: The `unattributedMisses` doc comment: a counter advance across a model or TTL change happened at an unknown rate; dropping it "would understate the miss rate", and pricing it at the arriving model's rate "overstated cost by ~8× on the capture DB". The cost is therefore a floor, and the three `unattributed*` fields tell a reader how large the unpriced slice is.
**Approved**: pending

**Decision**: `ttlKnown` is reported beside `ttl` instead of refusing to price an unknown TTL.
**Rationale**: The doc comment: an unknown spelling is priced at the API-default 1.25× premium "as a fallback, not as a measured rate", and "only this flag distinguishes that from a genuine 5-minute write", since a 1-hour entry under an unknown spelling is understated by 37.5%.
**Approved**: pending

**Decision**: `CacheMissesDTO` echoes `since` and reports `coverageStart` as strings with `""` sentinels.
**Rationale**: The report differences raw status-line events with no frozen rollup behind it, so retention can silently narrow any window; reporting where coverage begins "lets a caller tell 'no misses in that window' from 'no data left for it'" (the comment in `cacheMisses`). Empty strings, not optionals, keep both keys always present on the wire.
**Approved**: pending

**Decision**: Cache-miss counts are sums of observed increases, and a session's first tick counts nothing.
**Rationale**: The `CacheMissesDTO` doc comment: the status line re-renders cumulative counters on every tick, "so a row count is not a miss count", and a first tick's counters "describe misses that happened before this daemon was watching".
**Approved**: pending

**Decision**: Graph node ids are namespaced by kind (`session:`, `tool:`, `project:`), and `kind` and `status` are plain strings.
**Rationale**: The `GraphNodeDTO.id` doc comment: namespacing means "a session and a tool cannot collide" in one flat id space the JS renderer keys links by. Keeping `kind` and `status` as strings, with their values named only in doc comments, matches the rest of the file's open-string style; the cost is that the types cannot reject an unknown kind or status, which is why `node-kind-values` and `node-status-session` are producer guarantees.
**Approved**: pending

**Decision**: The graph snapshot is capped at 200 sessions even though the route accepts a `?limit=` up to 1000.
**Rationale**: The `graphSnapshot` doc comment: sessions are "Capped at 200 to keep the client-side force simulation interactive". The route's shared `boundedLimit(default: 100, max: 1000)` is applied first and the tighter clamp second, so a `limit` between 201 and 1000 is silently reduced; the snapshot reports no echo of the limit applied.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns passes: both files hold only data shapes, with computation in `DaemonDatabase`'s insights, rollup and graph queries and transport in `UsageRoutes`. Unit-test coverage is partial: `InsightsQueriesTests` asserts the field values the producers put into the insights types, but no test encodes or decodes any of the types themselves, so the snake_case wire names, the omitted `most_used_tool` and `status` keys and the verbatim `by_type` keys are untested, and no test exercises `graphSnapshot` at all. API design conventions pass: one key-naming rule applies to every field, the cache-miss report documents its sentinels, its floor-not-estimate cost and its truncation rule, and graph node ids are namespaced so link endpoints are unambiguous. Data integrity is partial: the doc comments state each count's meaning precisely, but the `DailyMetricDTO` comment that `valueSum` is always 0 is contradicted by the `project` metric, and graph link-to-node integrity rests on the producer alone, with nothing in the types to enforce it. No user-facing strings exist; every literal is an identifier.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-11-21 | Mike Fullerton | Resolved daily-metric-value-sum-zero: valueSum is 0 on every metric but project, where it is the day's distinct sessions, and the doc comments now say so; added vector 038. |
| 1.1.0 | 2026-11-21 | Mike Fullerton | Covers GraphSnapshotDTO.swift: the graph snapshot, node and link wire types for /visualization/graph |
