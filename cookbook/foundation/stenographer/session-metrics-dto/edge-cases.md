
- **Null and empty input**: Every `ImportSummary` key and every `ImportRequestDTO` field MAY be absent or `null`, and an absent `ImportSummary` key MUST decode to its default. A missing `SessionMetricsDTO` or `TranscriptCursorStatsDTO` required key MUST fail the decode; the cursor timestamps MAY be absent.
- **Boundary values**: Byte counts are Int64 and file and line counts are Int; no value is clamped, and a decoder MUST NOT reject `bytesOnDisk` below `bytesCovered`. A dry run still counts `linesSeen`.
- **Concurrent access**: The values are immutable and `Sendable`, so they MAY cross threads and actors freely. Concurrent import runs and their counters belong to the daemon.
- **Error states**: `ImportSummary.errors` is a list of strings the importer collected; the type carries it and does not interpret it. A decode failure for the strict types is a thrown `DecodingError`.
- **Offline or disconnected state**: Not applicable: the types perform no I/O.
- **Version skew**: A summary from an older peer that omits `has_more` or the cutoff MUST decode. A newer peer's unknown keys are ignored.
- **Cutoff over the wire**: `cutoffISO` survives a wire round trip because its coding key is `cutoffIso` (`summary-cutoff-wire-key`); a peer built before that fix decodes it as nil.
- **Date strategy**: A reader that decodes `since` without the shared ISO-8601 date strategy fails, so a reader MUST use the shared decoder.
- **Permanently dropped lines**: Invalid UTF-8 lines are counted in `linesSkipped` and never re-read (a consumer SHOULD surface a non-zero `linesSkipped` to flag lost content).

