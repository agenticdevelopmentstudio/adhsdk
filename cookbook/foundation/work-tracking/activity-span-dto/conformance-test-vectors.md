
Derived from the type's source and from `testStatusRoundTripsSnakeCase` in `WorkTrackingModelsTests`, which round-trips a `WorkTrackingStatus` holding an `ActivitySpanDTO`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| activity-span-dto-001 | required-init-arguments, string-defaults | `ActivitySpanDTO(bundleId: "com.apple.dt.Xcode", appName: "Xcode", startedAt: "2026-10-01T09:00:00Z", tz: "UTC")` | `windowTitle`, `workingPath`, `repoRoot`, `branch`, `endedAt`, `lastSeenAt` are all `""` |
| activity-span-dto-002 | default-id | Two inits with no `id` argument | Each `id` is a valid UUID string and the two differ |
| activity-span-dto-003 | identity-field | Init with `id: "s"` | `id == "s"` |
| activity-span-dto-004 | is-open-derivation, ended-at-sentinel | Span with `endedAt: ""` | `isOpen == true` |
| activity-span-dto-005 | is-open-derivation | Span with `endedAt: "2026-10-01T10:00:00Z"` | `isOpen == false` |
| activity-span-dto-006 | mutable-fields, is-open-derivation | Open span, then set `endedAt = "2026-10-01T10:00:00Z"` | `isOpen` flips from true to false |
| activity-span-dto-007 | mutable-fields, immutable-fields | Set `windowTitle` and `lastSeenAt` on a span | Both read back the new values; `id` and `startedAt` are unchanged |
| activity-span-dto-008 | codable-synthesis, snake-case-by-strategy | Encode with `convertToSnakeCase`, decode with `convertFromSnakeCase` a `WorkTrackingStatus` whose `currentSpan` is a span with id `s` (test `testStatusRoundTripsSnakeCase`) | Decoded value equals the original |
| activity-span-dto-009 | is-open-not-encoded | Encode an open span to JSON | The JSON has no `isOpen` or `is_open` key |
| activity-span-dto-010 | no-validation | Init with `startedAt: "not a date"` and `tz: ""` | Construction succeeds and both strings are stored unchanged |
| activity-span-dto-011 | value-semantics | Copy a span, set `endedAt` on the copy | The original `isOpen` remains true |
| activity-span-dto-012 | conformances | Compare two spans built with identical arguments including `id` | They are equal; spans differing only in `lastSeenAt` are not equal |
| activity-span-dto-013 | working-path-sentinel, repo-root-sentinel, last-seen-sentinel | Span built with defaults | `workingPath`, `repoRoot` and `lastSeenAt` are `""`, meaning unresolved, no repo, no heartbeat |
| activity-span-dto-014 | all-strings | Encode a span with the default encoder and inspect every value in the JSON object | Every value is a JSON string |
