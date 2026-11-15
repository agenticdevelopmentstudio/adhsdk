
`IngestionErrorLogTests` (database test target) exercises `IngestionErrorLogDTO` through `DaemonDatabase`; `IngestionErrorDTOConformanceTests` (Core test target) exercises `IngestionErrorDTO`, `RetryProgressDTO` and the log row's shape; vector 010 is a compile-time check and is skipped.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ingestion-error-dto-001 | error-init-defaults | `IngestionErrorDTO(filename: "a.json", eventType: "Stop", sessionId: "s1", quarantinedAt: "2026-11-10T09:00:00Z", reason: "disk full")` | `retryCount` 0, `lastRetriedAt` nil, `exhausted` false |
| ingestion-error-dto-002 | error-fields, error-exhausted | the same with `retryCount: 5`, `lastRetriedAt: "2026-11-10T09:05:00Z"`, `exhausted: true` | each field reads back; `exhausted` true |
| ingestion-error-dto-003 | log-fields, log-status-values | `IngestionErrorLogDTO` with `status: "recovered"`, `resolvedAt: "2026-11-10T09:06:00Z"`, `sqliteCode: 5` | each field reads back |
| ingestion-error-dto-004 | log-status-lost, log-resolved-at | a row with `status: "lost"`, `retryCount: 0`, `lastRetriedAt: nil`, `sqliteCode: nil` | `lastRetriedAt` nil, `sqliteCode` nil, `retryCount` 0 |
| ingestion-error-dto-005 | log-no-exhausted-flag | encode an `IngestionErrorLogDTO` | JSON has no `exhausted` key |
| ingestion-error-dto-006 | progress-fields | `RetryProgressDTO(running: true, total: 10, processed: 4, recovered: 3, stillFailing: 1)` | each field reads back |
| ingestion-error-dto-007 | progress-polling | a progress value with `running` false, `total` 10, `processed` 10, encoded then decoded | `running` reads false and `processed` equals `total`: the stop signal a poller reads (the poller is UI code, not tested here) |
| ingestion-error-dto-008 | error-last-retried | encode an `IngestionErrorDTO` with `lastRetriedAt` nil | the synthesized encoding omits the key; decode gives nil |
| ingestion-error-dto-009 | no-validation | `IngestionErrorLogDTO` with `status: "mystery"` | constructs; `status` reads `mystery` |
| ingestion-error-dto-010 | log-no-defaults | construct an `IngestionErrorLogDTO` | every argument must be written, nil included (a compile-time check, not a runtime vector) |
| ingestion-error-dto-011 | log-status-values, log-sqlite-code, log-resolved-at | record a failure twice for `a.json`, then once with `exhausted` true (`testAnUpsertKeepsTheFirstQuarantineTimeAndTracksTheLatestAttempt`) | one row; `quarantinedAt` stays the first time; `retryCount` 3; `status` `exhausted` |
| ingestion-error-dto-012 | log-status-values, log-resolved-at | resolve `a.json` (`testResolveMarksTheRowRecoveredAndStampsResolvedAt`) | `status` `recovered`; `resolvedAt` non-nil, where it was nil before |
| ingestion-error-dto-013 | log-status-values, log-resolved-at | clear the active rows with one failing, one exhausted and one recovered row (`testClearTouchesOnlyTheStillActiveRows`) | the failing and exhausted rows read `cleared` with `resolvedAt` set; the recovered row stays `recovered` |
| ingestion-error-dto-014 | log-status-lost | record a lost event for `empty.json`, then clear (`testALostEventIsATerminalResolvedRowThatClearLeavesAlone`) | `status` `lost`, `retryCount` 0, `resolvedAt` non-nil, `quarantinedAt` the detection time; clear leaves it `lost` |
| ingestion-error-dto-015 | log-resolved-at | record a failure for a recovered filename again (`testAResolvedFilenameQuarantinedAgainTakesAFreshQuarantineTime`) | `status` `failing`, `quarantinedAt` the new time, `resolvedAt` nil |

