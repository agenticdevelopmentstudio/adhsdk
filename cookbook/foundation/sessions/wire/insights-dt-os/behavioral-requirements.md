
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
- **daily-metric-value-sum-zero**: NEEDS REVIEW: Not implemented in source. The doc comment declares "`valueSum` is 0 in the current phase (counts only)", but `projectActivity` reads the `project` metric's `value_sum` as the day's distinct sessions and `testRecomputeEmitsProjectMetric` asserts `valueSum == 2`; the owner of the rollup must say whether the comment or the `project` metric is the contract.

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

