
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

**Decision**: The timestamps `firstTurnAt`, `lastTurnAt`, `updatedAt`, the cursor timestamps and `cutoffISO` stay opaque Strings, while `ImportRequestDTO.since` is a `Date`.
**Rationale**: The strings are the forms the daemon stored, so the DTO never parses them. The parse boundary for `cutoffISO` is the daemon's import pass, which stores the string as the `jsonl_import_last_run_at` setting and parses it back into a `Date` when it builds the next `since`; nothing on the wire does that round trip.
**Approved**: pending

**Decision**: `ImportRequestDTO.since` is a `Date`, written as ISO-8601 by the wire encoder.
**Rationale**: The doc comment fixes ISO-8601 for `since`; the shared wire definition keeps the three ends of a relayed request in one dialect.
**Approved**: pending

