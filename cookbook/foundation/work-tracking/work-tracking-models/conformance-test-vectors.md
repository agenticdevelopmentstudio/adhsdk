
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-models-001 | normalized-id-order, normalized-retention-clamp | `normalized()` on enabled preferences with added `["b","a","b"]`, removed `["z","z"]`, retentionDays 1 (test `testNormalizedSortsDedupsAndClamps`) | added `["a","b"]`, removed `["z"]`, retentionDays 7 |
| work-tracking-models-002 | normalized-retention-clamp | `normalized()` with retentionDays 99999 (same test) | retentionDays 3650 |
| work-tracking-models-003 | session-id-from-span | `ActivitySpanSession.sessionId(spanId: "X")` (test `testSpanSessionIdRoundTrips`) | `app:X` |
| work-tracking-models-004 | span-id-from-session | `spanId(sessionId: "app:X")` (same test) | `X` |
| work-tracking-models-005 | span-id-from-session | `spanId(sessionId: "claude-session")` (same test) | nil |
| work-tracking-models-006 | status-degraded | `WorkTrackingStatus(enabled: false, accessibility: .denied).isDegraded` (test `testDegradedOnlyWhenEnabledWithoutGrant`) | false |
| work-tracking-models-007 | status-degraded | enabled true with `.denied`, then enabled true with `.unknown` (same test) | true for both |
| work-tracking-models-008 | status-degraded | enabled true with `.granted` (same test) | false |
| work-tracking-models-009 | status-shape | A status with a `currentSpan`, `writeFailures` 2 and `lastError` `disk full`, encoded with snake-case keys and decoded with the matching strategy (test `testStatusRoundTripsSnakeCase`) | The decoded value equals the original |
| work-tracking-models-010 | preferences-default, default-retention-days | `WorkTrackingPreferences.default` | enabled false, both id lists empty, retentionDays 90 |
| work-tracking-models-011 | init-no-validation | `WorkTrackingPreferences(enabled: true, addedBundleIds: ["b","a","b"], removedBundleIds: [], retentionDays: 1)` | Fields stored exactly as given, with no sorting or clamping |
| work-tracking-models-012 | wire-read-failed-row, wire-read-failed-key | `String(decoding: WorkTrackingWire.readFailedRow, as: UTF8.self)` | `{"work_tracking_read_failed":true}` |
| work-tracking-models-013 | settings-keys | `WorkTrackingSettingsKeys.retentionDays` and `.accessibilitySigner` | `activity_retention_days` and `activity_ax_signer` |
| work-tracking-models-014 | status-defaults | `WorkTrackingStatus()` | enabled false, accessibility `.unknown`, currentSpan nil, writeFailures 0, lastError nil |

Vectors 010 to 014 are derived from the source and are tested in `WorkTrackingModelsTests` (`testV10_` to `testV14_`), including one that pins the exact bytes of `WorkTrackingWire.readFailedRow` for vector 012.
