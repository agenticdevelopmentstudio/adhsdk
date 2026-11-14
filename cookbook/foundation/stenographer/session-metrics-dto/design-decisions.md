
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

