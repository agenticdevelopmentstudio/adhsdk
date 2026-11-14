---
id: cda40dcf-db06-4171-a8f0-fbddf584f196
title: "Session Metrics and Import DTOs"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shared wire records for per-session token and cost metrics, the import request, transcript cursor coverage and the import run summary."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - dto
  - wire
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Session Metrics and Import DTOs

## Overview

Four records shared by the Stenographer daemon, the app and the `steno` CLI for transcript import. `SessionMetricsDTO` is the per-session aggregate of tokens, cost and turns sourced from Claude Code's JSONL transcripts; it is populated by the `steno import` command, not maintained in real time by hook ingestion, because hooks carry no token data. `ImportRequestDTO` is what `steno import` asks for (the body of `POST /import` and the XPC `importTranscripts`). `TranscriptCursorStatsDTO` reports how much of the transcripts on disk the byte cursors already cover. `ImportSummary` reports a completed import run.

All are immutable values with `let` fields, spelled in the stenographer-wide wire format (snake_case keys, ISO-8601 dates). `ImportSummary` has a hand-written tolerant decoder because the CLI and daemon binaries can be at different versions. The types hold no behavior: scanning, de-duplication, cursor handling and the chunked drain belong to the daemon's importer.

## Behavioral Requirements

**SessionMetricsDTO**

- **metrics-conformances**: `SessionMetricsDTO` MUST be an immutable `Codable` and `Sendable` value type; it does not declare `Equatable`.
- **metrics-field-set**: It MUST carry `sessionId` (String), `totalInputTokens`, `totalOutputTokens`, `cacheReadTokens`, `cacheCreationTokens` (Int), `totalCostUsd` (Double), `turnCount` (Int), `model` (String), and `firstTurnAt`, `lastTurnAt`, `updatedAt` (String).
- **metrics-init-all-required**: The public initializer MUST take all eleven fields in that order with no defaults.
- **metrics-model-meaning**: `model` MUST be the most recent model seen for the session, the last assistant turn's model.
- **metrics-source**: The metrics MUST be treated as populated by the transcript import only; the DTO documents they are not maintained by hooks.
- **metrics-wire-keys**: The keys MUST be `session_id`, `total_input_tokens`, `total_output_tokens`, `cache_read_tokens`, `cache_creation_tokens`, `total_cost_usd`, `turn_count`, `model`, `first_turn_at`, `last_turn_at`, `updated_at`.
- **metrics-decode-strict**: Decoding MUST fail when any key is missing; the type has no tolerant decoder.
- **metrics-timestamps-opaque**: The three timestamps MUST be carried as Strings exactly as stored.

**ImportRequestDTO**

- **request-field-set**: `ImportRequestDTO` MUST carry `sourceDirectory` (optional String), `since` (optional Date) and `dryRun` (optional Bool).
- **request-init-defaults**: The public initializer MUST default all three fields to nil.
- **request-empty-body**: Every field is optional, so an empty body MUST mean a full import from the default directory. The DTO documents this; the daemon applies the default directory.
- **request-wire-keys**: The keys MUST be `source_directory`, `since` and `dry_run`; absent optionals MUST be omitted on encode and read as nil on decode.
- **request-since-iso8601**: `since` MUST travel as an ISO-8601 date string through the shared wire encoder and decoder; a decoder built without the ISO-8601 date strategy will fail to read it.
- **request-delivery**: The request MUST be the body of both `POST /import` and the XPC `importTranscripts`.

**TranscriptCursorStatsDTO**

- **cursor-field-set**: `TranscriptCursorStatsDTO` MUST carry `files` (Int), `bytesCovered` and `bytesOnDisk` (Int64), and `oldestUpdatedAt` and `newestUpdatedAt` (optional String).
- **cursor-init-required**: The public initializer MUST take all five fields, none defaulted.
- **cursor-files-meaning**: `files` MUST be the number of files with a stored cursor.
- **cursor-bytes-covered**: `bytesCovered` MUST be the bytes already ingested across those files, which the next pass will skip.
- **cursor-bytes-on-disk**: `bytesOnDisk` MUST be the size of those files as recorded at the start of their last scan.
- **cursor-gap-rough**: `bytesOnDisk` can read slightly below `bytesCovered`, because Claude appends to live transcripts and a file that grew while being read has consumed more bytes than the earlier size stat; a consumer MUST treat the gap as a rough "still to read", not an exact remainder.
- **cursor-wire-keys**: The keys MUST be `files`, `bytes_covered`, `bytes_on_disk`, `oldest_updated_at` and `newest_updated_at`.

**ImportSummary**

- **summary-field-set**: `ImportSummary` MUST carry these Int fields: `filesScanned`, `turnsSeen`, `eventsInserted`, `eventsSkipped`, `sessionsCreated`, `sessionsTouched`, `metricsUpserted`, `linesSeen`, `linesInserted`, `linesSkipped`; these Int64 fields: `bytesRead`, `bytesSkipped`; the list of Strings `errors`; the Bool `hasMore`; and the optional String `cutoffISO`.
- **summary-init-defaults**: The public initializer MUST default every field: zero for the counters, an empty list for `errors`, false for `hasMore` and nil for `cutoffISO`.
- **summary-decode-tolerant**: The decoder MUST read every key with a present-or-nil read and fall back to the default (zero, an empty list, false, nil), so a peer that omits a newer field yields a usable summary instead of a missing-key failure. An empty object `{}` MUST decode to the all-default summary.
- **summary-decode-rationale**: The type is the daemon-to-CLI wire contract for `POST /import`, so the two binaries can be at different versions.
- **summary-encode-synthesized**: Encoding MUST be synthesized: every field is written, including zeros, an empty `errors` array and a nil-omitted `cutoffISO`.
- **summary-lines-seen**: `linesSeen` MUST count every transcript JSONL line seen across scanned files this run (not only user and assistant turns), counted even in a dry run.
- **summary-lines-inserted**: `linesInserted` MUST count lines actually inserted into `transcript_lines` this run; a re-run of already-captured files inserts 0 because of the session id plus hash de-duplication.
- **summary-lines-skipped**: `linesSkipped` MUST count non-empty lines dropped because their bytes were not valid UTF-8. They are permanently dropped: the byte cursor advances past them, nothing re-reads them, and a non-zero value is the only signal that a transcript lost content. It MUST be its own counter, not inferred from `linesSeen` minus `linesInserted`, since that gap is normally dedup.
- **summary-bytes-read**: `bytesRead` MUST be the bytes actually read off disk this run.
- **summary-bytes-skipped**: `bytesSkipped` MUST be the bytes the byte cursors let the run skip, the head of every scanned file already ingested. Zero with files being scanned means cursors are being rejected and every pass re-reads from byte zero; a healthy steady state reads kilobytes and skips gigabytes.
- **summary-has-more**: `hasMore` MUST be true when the importer hit its `maxFiles` option and stopped early, so chunked callers re-enqueue until it is false; it defaults to false for the unbounded CLI path.
- **summary-cutoff-meaning**: `cutoffISO` MUST be the ISO 8601 mtime of the latest file processed this run, which the chunked task path persists as the next `since` cutoff; it is nil when nothing was processed.
- **summary-cutoff-wire-key**: NEEDS REVIEW: Not implemented in source. For `cutoffISO`, through the shared wire coders the key is lost on the way back in: the wire encoder writes `cutoff_iso`, but the from-snake-case decoder rebuilds that as `cutoffIso`, which does not match the stored key `cutoffISO`, and because the decoder reads it with a present-or-nil read the field silently decodes as nil. The documented contract that the value reaches a consumer is therefore unmet for any wire reader. A test that round-trips a summary with a non-nil `cutoffISO` through `StenographerWire`, or a decision to spell the key `cutoffIso` as `memoryFootprintMb` is spelled, would settle it. The daemon's own chunked task reads the in-memory summary and is unaffected.

## Appearance

Not applicable — these are non-visual data transfer objects, not visual components.

## States

Not applicable — these are non-visual data transfer objects, not visual components.

## Accessibility

Not applicable — these are non-visual data transfer objects, not visual components.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-metrics-dto-001 | summary-decode-tolerant | Decode `{}` as `ImportSummary` | Succeeds; all counters 0, `errors` empty, `hasMore` false, `cutoffISO` nil |
| session-metrics-dto-002 | summary-decode-tolerant | Decode a body with `files_scanned` 3 and `has_more` true only | `filesScanned` 3, `hasMore` true, everything else default |
| session-metrics-dto-003 | summary-init-defaults | Construct `ImportSummary()` | Every field at its default, `cutoffISO` nil (the same nil default shows in JSONLImporterTests `testAScopedRunReportsNoCutoff`, where the importer builds a summary for a scoped run) |
| session-metrics-dto-004 | summary-cutoff-meaning | An importer run that processed files (JSONLImporterTests chunked-drain tests) | `cutoffISO` is non-nil and parses as an ISO-8601 date |
| session-metrics-dto-005 | summary-cutoff-wire-key | Encode `ImportSummary(cutoffISO: "2026-01-01T00:00:00Z")` with the wire encoder and decode the bytes with the wire decoder | The JSON key is `cutoff_iso`; the decoded `cutoffISO` is nil (verified against the source with a standalone snippet) |
| session-metrics-dto-006 | summary-bytes-read, summary-bytes-skipped | Encode a summary with `bytesRead` 5 000 000 000 and `bytesSkipped` 9 000 000 000 | Keys `bytes_read` and `bytes_skipped` carry the full Int64 values with no truncation |
| session-metrics-dto-007 | request-empty-body | Decode `{}` as `ImportRequestDTO` | `sourceDirectory`, `since` and `dryRun` are nil |
| session-metrics-dto-008 | request-since-iso8601, request-wire-keys | Encode `ImportRequestDTO(sourceDirectory: "/x", since: <date>, dryRun: true)` with the wire encoder | Keys `source_directory`, `since` (ISO-8601 string) and `dry_run`; decoding with the wire decoder returns the same values |
| session-metrics-dto-009 | request-since-iso8601 | Decode a body with `since` `2026-01-01T00:00:00Z` using a default `JSONDecoder` | Throws a type-mismatch error; the wire decoder succeeds |
| session-metrics-dto-010 | metrics-wire-keys, metrics-field-set | Encode then decode a metrics value with the wire coders | Keys as listed; all eleven fields round-trip, `totalCostUsd` as a Double |
| session-metrics-dto-011 | metrics-decode-strict | Decode a metrics body with `turn_count` removed | Throws a key-not-found error |
| session-metrics-dto-012 | cursor-wire-keys, cursor-gap-rough | Decode `{"files":2,"bytes_covered":1000,"bytes_on_disk":990}` | `files` 2, `bytesCovered` 1000, `bytesOnDisk` 990, both timestamps nil; no check enforces `bytesOnDisk` at least `bytesCovered` |
| session-metrics-dto-013 | cursor-init-required | Construct with `oldestUpdatedAt` and `newestUpdatedAt` nil | Fields read back as given |

## Edge Cases

- **Null and empty input**: Every `ImportSummary` key and every `ImportRequestDTO` field MAY be absent or `null` (MUST decode to the default). A missing `SessionMetricsDTO` or `TranscriptCursorStatsDTO` required key MUST fail the decode; the cursor timestamps MAY be absent.
- **Boundary values**: Byte counts are Int64 and file and line counts are Int; no value is clamped, and `bytesOnDisk` below `bytesCovered` is valid (MUST NOT be rejected). A dry run still counts `linesSeen`.
- **Concurrent access**: The values are immutable and `Sendable`, so they MAY cross threads and actors freely. Concurrent import runs and their counters belong to the daemon.
- **Error states**: `ImportSummary.errors` is a list of strings the importer collected; the type carries it and does not interpret it. A decode failure for the strict types is a thrown `DecodingError`.
- **Offline or disconnected state**: Not applicable: the types perform no I/O.
- **Version skew**: A summary from an older peer that omits `has_more` or the cutoff decodes (MUST). A newer peer's unknown keys are ignored.
- **Silent cutoff loss**: Over the wire, `cutoffISO` decodes as nil even when sent (the open question on `summary-cutoff-wire-key`); `hasMore` still travels correctly.
- **Date strategy**: A reader that decodes `since` without the shared ISO-8601 date strategy fails (MUST be avoided; use the shared decoder).
- **Permanently dropped lines**: Invalid UTF-8 lines are counted in `linesSkipped` and never re-read (MUST be surfaced to the user by the consumer if it wants to flag lost content).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ImportRequestDTO` fields | String, Date, Bool optionals | nil | All unset means a full import from the default directory. |
| `ImportSummary` initializer parameters | Int, Int64, array, Bool, optional String | 0, 0, empty, false, nil | Every field has a default. |
| wire coding strategy | snake_case keys, ISO-8601 dates | `StenographerWire` | Callers use the shared encoder and decoder. |

## Deep Linking

Not applicable: these types define no URL or deep link; `POST /import` is a daemon API route.

## Localization

Not applicable: the types hold no user-facing literal; `errors` entries are developer-facing messages the importer writes.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: Session identifiers, model names, token and cost totals and turn times; `sourceDirectory` is a local path.
- **Storage**: The types store nothing; the daemon persists metrics and transcript lines.
- **Transmission**: Over XPC and over HTTP on the daemon's loopback address.
- **Retention**: Not set by these types.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Plain Swift with no view code. Render coverage as a progress figure from `bytesCovered` and `bytesOnDisk`, clamping the ratio at 1 because the gap can be negative.
- **Compose**: `kotlinx.serialization` data classes with snake_case `@SerialName`, `Long` for the Int64 fields, `Instant` for `since` with ISO-8601 text. Give every `ImportSummary` property a default so a missing key decodes, and keep the metrics and cursor keys required. Name the cutoff key explicitly so it round-trips.
- **React/Web**: TypeScript interfaces with snake_case keys; byte counts beyond 2^53 lose precision in a JavaScript number, so use a string or `BigInt` reader if sizes can exceed it. Send `since` as an ISO-8601 string. Default missing summary keys on read.
- **AppKit / UIKit**: Source file `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SessionMetricsDTO.swift`. Foundation-only; `ImportSummary` has a hand-written decoder with a custom `CodingKeys`, and that decoder's key spelling for the cutoff interacts with the from-snake-case strategy as described in the open question.
- **WinUI 3**: Use C# records with `System.Text.Json` and `JsonNamingPolicy.SnakeCaseLower`; `long` for `bytesCovered`, `bytesOnDisk`, `bytesRead` and `bytesSkipped`, `DateTimeOffset?` for `since` (the default converter reads and writes ISO-8601), `double` for `TotalCostUsd`. Give `ImportSummary` properties initializers (`int FilesScanned { get; init; }`, `string[] Errors { get; init; } = []`, `bool HasMore { get; init; }`, `string? CutoffIso { get; init; }`) so an absent key decodes to the default, and set `[JsonPropertyName("cutoff_iso")]` explicitly on the cutoff so it reads back (the snake-case policy would produce `cutoff_iso` anyway, which is the spelling the source writes). Use `JsonIgnoreCondition.WhenWritingNull` for the request's optionals. Post the request with `HttpClient.PostAsJsonAsync` to the loopback `/import` and read the reply with `ReadFromJsonAsync<ImportSummary>`; show progress with a `ProgressBar` bound through `INotifyPropertyChanged`, and expose the cursor figures in an `ObservableCollection` row model. For the daemon side in ASP.NET Core, map `POST /import` as a minimal API route with `IHostedService` driving the chunked drain.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SessionMetricsDTO.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `ImportSummary` decodes every field tolerantly while `SessionMetricsDTO` and `TranscriptCursorStatsDTO` stay strict.
**Rationale**: The summary is the daemon-to-CLI contract for `POST /import` and the two binaries can be at different versions, so a newer field such as `hasMore` or `cutoffISO` must not crash an older reader. The metrics and cursor records have no such skew path recorded in the source.
**Approved**: pending

**Decision**: `linesSkipped` is a counter of its own.
**Rationale**: Invalid-UTF-8 lines are dropped for good because parking the cursor on an undecodable line would stall the import forever; the counter is the only signal of lost content, and `linesSeen` minus `linesInserted` cannot stand in because that gap is normally dedup.
**Approved**: pending

**Decision**: `bytesOnDisk` is sampled at the start of a file's last scan, so it can read below `bytesCovered`.
**Rationale**: Claude appends to live transcripts; the figure is a rough "still to read", not an exact remainder.
**Approved**: pending

**Decision**: `bytesRead` beside `bytesSkipped` is the cursor's health signal.
**Rationale**: Healthy steady state reads kilobytes and skips gigabytes; skipped at 0 while files are scanned means cursors are being rejected and every pass re-reads from byte zero.
**Approved**: pending

**Decision**: `cutoffISO` is spelled with an all-caps trailing acronym in the Swift property and in the hand-written `CodingKeys`.
**Rationale**: Recorded as a defect, not a choice: the from-snake-case decoder rebuilds `cutoff_iso` as `cutoffIso`, so a wire read yields nil (the casing trap the health record documents for `Mb`). The in-process chunked path is unaffected. The fix is a key spelling, which is why the open question sits on `summary-cutoff-wire-key`.
**Approved**: pending

**Decision**: `ImportRequestDTO.since` is a `Date`, written as ISO-8601 by the wire encoder.
**Rationale**: The doc comment fixes ISO-8601 for `since`; the shared wire definition keeps the three ends of a relayed request in one dialect.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

separation-of-concerns passes: the file declares four shapes and one tolerant decoder; scanning, dedup, cursors and the chunked drain live in the daemon importer. unit-test-coverage is partial: `JSONLImporterTests` asserts `cutoffISO`, `hasMore` and the counters on summaries the importer builds, but no test encodes or decodes any of the four records through the wire coders, so vectors 001, 002, 005 and 007 to 012 follow from the source with no test of their own. data-integrity is partial because a wire read of `ImportSummary` silently loses `cutoffISO`, as described in the open question on `summary-cutoff-wire-key`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
