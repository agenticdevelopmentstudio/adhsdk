
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-metrics-dto-001 | summary-decode-tolerant | Decode `{}` as `ImportSummary` | Succeeds; all counters 0, `errors` empty, `hasMore` false, `cutoffISO` nil |
| session-metrics-dto-002 | summary-decode-tolerant | Decode a body with `files_scanned` 3 and `has_more` true only | `filesScanned` 3, `hasMore` true, everything else default |
| session-metrics-dto-003 | summary-init-defaults | Construct `ImportSummary()` | Every field at its default, `cutoffISO` nil (the same nil default shows in JSONLImporterTests `testAScopedRunReportsNoCutoff`, where the importer builds a summary for a scoped run) |
| session-metrics-dto-004 | summary-cutoff-meaning | Integration check, not a DTO test: an importer run that processed files (JSONLImporterTests chunked-drain tests) | `cutoffISO` is non-nil and parses as an ISO-8601 date |
| session-metrics-dto-005 | summary-cutoff-wire-key | Encode `ImportSummary(cutoffISO: "2026-01-01T00:00:00Z")` with the wire encoder and decode the bytes with the wire decoder | The JSON key is `cutoff_iso`; the decoded `cutoffISO` equals `"2026-01-01T00:00:00Z"`. |
| session-metrics-dto-006 | summary-bytes-read, summary-bytes-skipped | Encode a summary with `bytesRead` 5 000 000 000 and `bytesSkipped` 9 000 000 000 | Keys `bytes_read` and `bytes_skipped` carry the full Int64 values with no truncation |
| session-metrics-dto-007 | request-empty-body | Decode `{}` as `ImportRequestDTO` | `sourceDirectory`, `since` and `dryRun` are nil |
| session-metrics-dto-008 | request-since-iso8601, request-wire-keys | Encode `ImportRequestDTO(sourceDirectory: "/x", since: <date>, dryRun: true)` with the wire encoder | Keys `source_directory`, `since` (ISO-8601 string) and `dry_run`; decoding with the wire decoder returns the same values |
| session-metrics-dto-009 | request-since-iso8601 | Decode a body with `since` `2026-01-01T00:00:00Z` using a default `JSONDecoder` | Throws a type-mismatch error; the wire decoder succeeds |
| session-metrics-dto-010 | metrics-wire-keys, metrics-field-set | Encode then decode a metrics value with the wire coders | Keys as listed; all eleven fields round-trip, `totalCostUsd` as a Double |
| session-metrics-dto-011 | metrics-decode-strict | Decode a metrics body with `turn_count` removed | Throws a key-not-found error |
| session-metrics-dto-012 | cursor-wire-keys, cursor-gap-rough | Decode `{"files":2,"bytes_covered":1000,"bytes_on_disk":990}` | `files` 2, `bytesCovered` 1000, `bytesOnDisk` 990, both timestamps nil; no check enforces `bytesOnDisk` at least `bytesCovered` |
| session-metrics-dto-013 | cursor-init-required | Construct with `oldestUpdatedAt` and `newestUpdatedAt` nil | Fields read back as given |
| session-metrics-dto-014 | summary-encode-synthesized | Encode `ImportSummary()` with the wire encoder | Every counter key is present with value 0, `errors` is `[]`, `has_more` is false and `cutoff_iso` is absent |
| session-metrics-dto-015 | request-init-defaults | Construct `ImportRequestDTO()` | `sourceDirectory`, `since` and `dryRun` are nil |
| session-metrics-dto-016 | metrics-init-all-required, metrics-field-set | Construct a `SessionMetricsDTO` passing all eleven fields in order | Each field reads back as given; omitting any argument does not compile |
| session-metrics-dto-017 | metrics-conformances | Pass a `SessionMetricsDTO` to a generic function constrained to `Codable & Sendable` | Compiles; the type does not declare `Equatable` |
