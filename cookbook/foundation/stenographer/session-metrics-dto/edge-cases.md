
- **Null and empty input**: Every `ImportSummary` key and every `ImportRequestDTO` field MAY be absent or `null` (MUST decode to the default). A missing `SessionMetricsDTO` or `TranscriptCursorStatsDTO` required key MUST fail the decode; the cursor timestamps MAY be absent.
- **Boundary values**: Byte counts are Int64 and file and line counts are Int; no value is clamped, and `bytesOnDisk` below `bytesCovered` is valid (MUST NOT be rejected). A dry run still counts `linesSeen`.
- **Concurrent access**: The values are immutable and `Sendable`, so they MAY cross threads and actors freely. Concurrent import runs and their counters belong to the daemon.
- **Error states**: `ImportSummary.errors` is a list of strings the importer collected; the type carries it and does not interpret it. A decode failure for the strict types is a thrown `DecodingError`.
- **Offline or disconnected state**: Not applicable: the types perform no I/O.
- **Version skew**: A summary from an older peer that omits `has_more` or the cutoff decodes (MUST). A newer peer's unknown keys are ignored.
- **Silent cutoff loss**: Over the wire, `cutoffISO` decodes as nil even when sent (the open question on `summary-cutoff-wire-key`); `hasMore` still travels correctly.
- **Date strategy**: A reader that decodes `since` without the shared ISO-8601 date strategy fails (MUST be avoided; use the shared decoder).
- **Permanently dropped lines**: Invalid UTF-8 lines are counted in `linesSkipped` and never re-read (MUST be surfaced to the user by the consumer if it wants to flag lost content).

