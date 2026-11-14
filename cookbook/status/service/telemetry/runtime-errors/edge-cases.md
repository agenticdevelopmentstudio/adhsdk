
- **Empty entries**: `groupRuntimeEntries([])` MUST return `[]`; `runtimeErrorsReport([], null, now)` MUST give `total` 0, `readAt` null, `complete` true.
- **Missing level**: a log event with no level MUST be dropped as `info`.
- **Wrong-typed fields**: a numeric `requestPath` or an empty-string `requestId` MUST read as absent (null).
- **Empty path after cut**: a path of only a query string MUST become `/`; a literally empty path stays null.
- **Message with no newline or empty message**: the head MUST be the trimmed whole line, or empty.
- **Multi-line message**: only the first line enters the head and the key; stack lines never split a group.
- **Long message**: the head MUST be cut to 200 characters but the shape MUST be taken first.
- **Ids of varying length in messages or paths**: MUST land in one group.
- **Digit-only word in a path**: `/2024` reads `:id`; `facebook-account` stays a word.
- **Unknown level in a group**: `worseLevel` keeps the known level; a group made only of unknown levels keeps the first entry's.
- **Equal sort keys**: report order falls through count, `lastSeen`, then `key`, so it is total and stable.
- **More than 200 groups**: the report MUST cap at 200 and keep `total` at the true count.
- **Stale read**: groups from an old read MUST stay, dated by `readAt`.
- **No read yet**: `readAt` null and `complete` true.
- **Store unavailable**: a rejecting `load` or `lastRead` MUST propagate; this module neither retries nor falls back.
- **Concurrent access**: the pure functions share no state and cannot interleave; the two store reads are concurrent and not atomic (see `report-load-consistency`).
- **Offline or network**: not applicable here; the network belongs to the fetcher (`fetchers/vercel-runtime.ts`).

