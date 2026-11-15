
**SessionMetricsDTO**

- **metrics-conformances**: `SessionMetricsDTO` MUST be an immutable `Codable` and `Sendable` value type; it does not declare `Equatable`.
- **metrics-field-set**: It MUST carry `sessionId` (String), `totalInputTokens`, `totalOutputTokens`, `cacheReadTokens`, `cacheCreationTokens` (Int), `totalCostUsd` (Double), `turnCount` (Int), `model` (String), and `firstTurnAt`, `lastTurnAt`, `updatedAt` (String).
- **metrics-init-all-required**: The public initializer MUST take all eleven fields in that order with no defaults.
- **metrics-model-meaning**: `model` holds the most recent model seen for the session, the last assistant turn's model. The importer fills it; the DTO does not enforce it.
- **metrics-source**: The metrics are populated by the transcript import only; the DTO documents that hooks do not maintain them.
- **metrics-wire-keys**: The keys MUST be `session_id`, `total_input_tokens`, `total_output_tokens`, `cache_read_tokens`, `cache_creation_tokens`, `total_cost_usd`, `turn_count`, `model`, `first_turn_at`, `last_turn_at`, `updated_at`.
- **metrics-decode-strict**: Decoding MUST fail when any key is missing; the type has no tolerant decoder.
- **metrics-timestamps-opaque**: The three timestamps MUST be carried as Strings exactly as stored.

**ImportRequestDTO**

- **request-field-set**: `ImportRequestDTO` MUST carry `sourceDirectory` (optional String), `since` (optional Date) and `dryRun` (optional Bool).
- **request-init-defaults**: The public initializer MUST default all three fields to nil.
- **request-empty-body**: Every field is optional, so an empty body MUST mean a full import from the default directory. The DTO documents this; the daemon applies the default directory.
- **request-wire-keys**: The keys MUST be `source_directory`, `since` and `dry_run`; absent optionals MUST be omitted on encode and read as nil on decode.
- **request-since-iso8601**: `since` MUST travel as an ISO-8601 date string through the shared wire encoder and decoder; a decoder built without the ISO-8601 date strategy will fail to read it.
- **request-delivery**: The request is the body of both `POST /import` and the XPC `importTranscripts`; the daemon and the client apply it.

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
- **summary-encode-synthesized**: Encoding MUST be synthesized: every field is written, including zeros, an empty `errors` array and a nil-omitted `cutoffISO`.
- **summary-lines-seen**: `linesSeen` MUST count every transcript JSONL line seen across scanned files this run (not only user and assistant turns), counted even in a dry run.
- **summary-lines-inserted**: `linesInserted` MUST count lines actually inserted into `transcript_lines` this run; a re-run of already-captured files inserts 0 because of the session id plus hash de-duplication.
- **summary-lines-skipped**: `linesSkipped` MUST count non-empty lines dropped because their bytes were not valid UTF-8. They are permanently dropped: the byte cursor advances past them, nothing re-reads them, and a non-zero value is the only signal that a transcript lost content. It MUST be its own counter, not inferred from `linesSeen` minus `linesInserted`, since that gap is normally dedup.
- **summary-bytes-read**: `bytesRead` MUST be the bytes actually read off disk this run.
- **summary-bytes-skipped**: `bytesSkipped` MUST be the bytes the byte cursors let the run skip, the head of every scanned file already ingested. Zero with files being scanned means cursors are being rejected and every pass re-reads from byte zero; a healthy steady state reads kilobytes and skips gigabytes.
- **summary-has-more**: `hasMore` is true when the importer hit its `maxFiles` option and stopped early, so chunked callers re-enqueue until it is false; it defaults to false for the unbounded CLI path. The importer sets it; the DTO does not enforce it.
- **summary-cutoff-meaning**: `cutoffISO` holds the ISO 8601 mtime of the latest file processed this run, which the chunked task path persists as the next `since` cutoff; it is nil when nothing was processed. The importer sets it; the DTO does not enforce it.
- **summary-cutoff-wire-key**: `cutoffISO` MUST round-trip through `StenographerWire`. Its coding key's raw value is `cutoffIso`, so the encoder writes `cutoff_iso` and the from-snake-case decoder, which rebuilds `cutoff_iso` as `cutoffIso`, reads it back. A raw value of `cutoffISO` would decode as nil.

