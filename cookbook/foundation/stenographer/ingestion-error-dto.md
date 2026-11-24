---
id: 95ea4062-09e5-4342-a376-413cb7deb7d1
title: "Ingestion Error DTOs"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The quarantined hook-event file, its persistent error-log row with resolved history, and the live progress of a Retry All batch, as the daemon surfaces them."
platforms:
  - swift
  - macos
tags:
  - stenographer
  - foundation
  - dto
  - wire
depends-on: []
related:
  - 96f73261-cf32-42cc-92f3-f8b58542382a
  - e8286557-84ee-4f45-b78c-f1d184c51a37
references: []
approved-by: ""
approved-date: ""
---

# Ingestion Error DTOs

## Overview

Three shapes describe hook events the daemon could not ingest. `IngestionErrorDTO` is one quarantined hook-event file still on disk, surfaced to the app over XPC and to the CLI over HTTP. `IngestionErrorLogDTO` is one row of the persistent ingestion-error log (DB table `ingestion_errors`), surfaced at `GET /ingestion/errors/log`; it includes resolved history. `RetryProgressDTO` is the live progress of a Retry All batch, which the daemon runs asynchronously and the UI polls until `running` is false. The quarantine, the retry budget, the table and the batch are the daemon's (`QuarantineService` and `DaemonDatabase`), outside this file; this code is the wire shape.

## Behavioral Requirements

- **timestamp-format**: `quarantinedAt`, `lastRetriedAt`, `updatedAt` and `resolvedAt` are Strings that the daemon writes as ISO-8601 times (`ISO8601DateFormatter`).
- **error-fields**: An `IngestionErrorDTO` MUST carry `filename`, `eventType`, `sessionId`, `quarantinedAt`, `reason` (String), `retryCount` (Int), `lastRetriedAt` (optional String) and `exhausted` (Bool).
- **error-live-file**: An `IngestionErrorDTO` MUST describe a file still quarantined on disk; the daemon's `QuarantineService.list()` builds one per event file in the errors directory, not counting `.meta.json` sidecars.
- **error-reason**: `reason` MUST be read from the file's `.meta.json` sidecar, or be the placeholder `unknown (quarantined before reason capture)` for a file quarantined before reason capture.
- **error-retry-count**: `retryCount` MUST count failed self-healing retries so far, with 0 meaning not yet retried.
- **error-last-retried**: `lastRetriedAt` MUST be an ISO-8601 time of the most recent retry, and MUST be nil when the file was never retried.
- **error-exhausted**: `exhausted` MUST be true once `retryCount` reaches the configured maximum (the daemon's `maxRetries`, default 3, raised to at least 1), and these are the files the menubar alert badge counts.
- **error-init-defaults**: `IngestionErrorDTO.init` MUST default `retryCount` to 0, `lastRetriedAt` to nil and `exhausted` to false.
- **log-fields**: An `IngestionErrorLogDTO` MUST carry `filename`, `eventType`, `sessionId`, `reason`, `quarantinedAt`, `status`, `updatedAt` (String), `sqliteCode` (optional Int), `retryCount` (Int), `lastRetriedAt` (optional String) and `resolvedAt` (optional String).
- **log-includes-history**: An `IngestionErrorLogDTO` MUST describe a log row whether or not the file is still on disk, including resolved history.
- **log-status-values**: `status` MUST be one of `failing`, `exhausted`, `recovered`, `cleared` or `lost`: the daemon writes `failing` or `exhausted` when it records a failure, `recovered` when the event is finally ingested, `cleared` for every still-active row when the user clears the quarantine, and `lost` for an empty drop file.
- **log-status-lost**: `lost` MUST mean a drop file arrived empty, so its event is gone; it is recorded once per `filename`, never retried and never counted as a live failure. Its row has an empty `eventType` and `sessionId`, `retryCount` 0, nil `lastRetriedAt` and `sqliteCode`, the fixed `reason` `empty drop file — the event was lost before it was written`, `quarantinedAt` set to the detection time, and `resolvedAt` set on arrival.
- **log-sqlite-code**: `sqliteCode` MUST be the SQLite result code behind the failure when one exists, and nil otherwise.
- **log-resolved-at**: `resolvedAt` MUST be nil for a `failing` or `exhausted` row, and set for a `recovered`, `cleared` or `lost` row; recording a new failure for a resolved filename resets it to nil.
- **log-no-defaults**: `IngestionErrorLogDTO.init` MUST take every field with no default, nil included.
- **log-no-exhausted-flag**: `IngestionErrorLogDTO` MUST NOT carry an `exhausted` Bool; exhaustion there is the `status` value `exhausted`.
- **progress-fields**: A `RetryProgressDTO` MUST carry `running` (Bool), `total`, `processed`, `recovered` and `stillFailing` (Int).
- **progress-total**: `total` MUST be the batch size: every quarantined event file for a Retry All, or the files taken by a periodic self-healing batch, which is bounded by its limit.
- **progress-processed**: `processed` MUST count the files attempted so far, including a file that vanished (cleared or removed elsewhere) before its retry.
- **progress-recovered**: `recovered` MUST count the files that ingested and were removed.
- **progress-still-failing**: `stillFailing` MUST count the files whose retry failed, which stay quarantined.
- **progress-polling**: A client MUST poll `RetryProgressDTO` until `running` is false after starting a batch.
- **progress-async**: The Retry All batch MUST run off the XPC and HTTP reply thread, so a large backlog cannot time the caller out; starting it while a batch is running changes nothing and returns the live progress. The periodic self-healing batch runs on its scheduler's task and fills the same counters.
- **conformance-protocols**: `IngestionErrorDTO`, `IngestionErrorLogDTO` and `RetryProgressDTO` MUST be `Codable` and `Sendable`; they are not declared `Equatable`.
- **unknown-status**: A client MUST handle a `status` outside the five values, since the type is a String and decodes any value.
- **no-validation**: The initializers MUST NOT validate: `status` is an unconstrained String here, and counts that do not add up are accepted.

## Appearance

Not applicable — this is a set of data shapes, not a visual component.

## States

Not applicable — this is a set of data shapes, not a visual component.

## Accessibility

Not applicable — this is a set of data shapes, not a visual component.

## Conformance Test Vectors

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

## Edge Cases

- **Never retried**: `retryCount` is 0 and `lastRetriedAt` is nil; the shape MUST carry both.
- **Placeholder reason**: a file quarantined before reason capture has a placeholder `reason`; the daemon writes `unknown (quarantined before reason capture)`.
- **Empty drop file**: see `#requirements/log-status-lost`.
- **Unknown status**: a `status` outside the five values still decodes, since the type is a String; see `#requirements/unknown-status`.
- **Empty batch**: Retry All over an empty errors directory sets `total` 0; `running` is true only until the batch finishes, then false with every count at 0.
- **Counts out of step**: `recovered` plus `stillFailing` may not equal `processed`, mid-batch or after it, because a file that vanished is processed but neither recovered nor failing; nothing here enforces the sum.
- **Batch already running**: starting Retry All while a manual or periodic batch runs starts nothing and returns the live progress; a periodic batch that finds a manual one running does nothing.
- **Re-quarantined filename**: a filename recorded as `recovered` or `cleared` and then failing again takes the new quarantine time and a nil `resolvedAt`.
- **Concurrent access**: all three are immutable `Sendable` values; a progress value is a snapshot, so a poll reads whatever the batch had reached.
- **Error and offline states**: no I/O here; a timed-out caller is what the async batch avoids, and an unreachable daemon is the client's failure.

## Configuration

Not applicable: nothing here is consumer-configurable. The initializer defaults are in `error-init-defaults`, and `exhausted` is derived from the daemon's `maxRetries` (see `error-exhausted`).
## Deep Linking

Not applicable: the shapes define no URL or deep link; `GET /ingestion/errors/log` is the daemon's route, named only in a doc comment.

## Localization

Not applicable: `reason` is a diagnostic string produced by the daemon or read from a sidecar file, and no user-facing string is defined here.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: the quarantined file's name, the event type, the session id and the failure reason.
- **Storage**: none here; the daemon keeps the files on disk and the rows in the `ingestion_errors` table.
- **Transmission**: values cross XPC to the app and HTTP to the CLI on the local machine; this code opens no connection.
- **Retention**: defined by the daemon; the log keeps resolved rows as history.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: A consumer view can bind an error list to `IngestionErrorDTO` rows, a badge counts those with `exhausted` true, and a Retry All sheet polls `RetryProgressDTO` into a `ProgressView`.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; optional fields are nullable with a default of null; model `status` as a String with a helper enum for the five known values.
- **React/Web**: TypeScript interfaces with `lastRetriedAt: string | null`; a polling hook (interval plus `running` check) stands in for the progress poll.
- **AppKit / UIKit**: Bind `IngestionErrorDTO` rows to an `NSTableView` data source (or `UITableView` on iOS), and drive an `NSProgressIndicator` (or `UIProgressView`) from `RetryProgressDTO` by polling until `running` is false; the structs are `Codable` and `Sendable`, so they cross XPC as payloads.
- **WinUI 3**: Use C# records with `System.Text.Json` (`string?` and `int?` for the optionals); `HttpClient` calls the log route; a `DispatcherTimer` or `PeriodicTimer` polls progress until `Running` is false and updates `ObservableCollection` rows and a `ProgressBar` (`Maximum` from `Total`, `Value` from `Processed`); an `InfoBadge` over the nav item shows the exhausted count.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/IngestionErrorDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The live file and the log row are separate shapes.
**Rationale**: The source states the log row, unlike `IngestionErrorDTO` (a live file still on disk), includes resolved history, so `status` and `resolvedAt` exist only on the log.
**Approved**: pending

**Decision**: An empty drop file is the status `lost`, recorded once and never retried.
**Rationale**: The source states its event is gone, so retrying cannot help and counting it would inflate live failures.
**Approved**: pending

**Decision**: Retry All runs asynchronously and is observed through `RetryProgressDTO`.
**Rationale**: The source states it runs off the XPC and HTTP reply thread so that a large backlog cannot time the caller out.
**Approved**: pending

**Decision**: `status` is a String and not an enum.
**Rationale**: The source types it String and lists five values in a comment; a new value decodes without a shape change, at the cost of no compile-time check; a client parses `status` at the boundary into its own enum with an `unknown` case.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | reliability |

separation-of-concerns passes: the file holds three shapes; quarantine, retry and persistence are the daemon's. unit-test-coverage is partial: `IngestionErrorLogTests` covers the log row's status lifecycle through the database, and `IngestionErrorDTOConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/IngestionErrorDTOConformanceTests.swift`) covers vectors 001 to 009; vector 010 is skipped because it is a compile-time check with no runtime behavior. error-recovery passes: the shapes expose the retry budget (`retryCount`, `exhausted`), resolved states and batch progress that a recovery UI needs.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (IngestionErrorDTOConformanceTests.swift, 9 of 10 new vectors plus 011-015 already covered by IngestionErrorLogTests); unit-test-coverage now partial (vector 010 is a compile-time check, skipped). |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Stated ISO-8601 timestamps, added an unknown-status requirement, deduplicated the lost and maxRetries text, clarified the empty batch, set Configuration to not applicable, fixed the SwiftUI and AppKit notes, and added related links. |
