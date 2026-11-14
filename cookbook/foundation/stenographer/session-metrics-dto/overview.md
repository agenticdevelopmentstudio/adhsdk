
Four records shared by the Stenographer daemon, the app and the `steno` CLI for transcript import. `SessionMetricsDTO` is the per-session aggregate of tokens, cost and turns sourced from Claude Code's JSONL transcripts; it is populated by the `steno import` command, not maintained in real time by hook ingestion, because hooks carry no token data. `ImportRequestDTO` is what `steno import` asks for (the body of `POST /import` and the XPC `importTranscripts`). `TranscriptCursorStatsDTO` reports how much of the transcripts on disk the byte cursors already cover. `ImportSummary` reports a completed import run.

All are immutable values with `let` fields, spelled in the stenographer-wide wire format (snake_case keys, ISO-8601 dates). `ImportSummary` has a hand-written tolerant decoder because the CLI and daemon binaries can be at different versions. The types hold no behavior: scanning, de-duplication, cursor handling and the chunked drain belong to the daemon's importer.

