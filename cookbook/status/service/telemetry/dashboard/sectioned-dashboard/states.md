
Not applicable — this is a cache and scheduler, not a visual component. Its runtime states are described below instead of in a visual-state table.

Per key: **idle** (`refreshing` false, `inflight` null), **refreshing** (`refreshing` true, `inflight` set). A read in idle with a due section moves the key to refreshing. A refresh finishing moves it back to idle. Per section: **never fetched** (`dueAt` 0), **fresh** (`dueAt` in the future after a success), **backing off** (`dueAt` in the future after a failure or incomplete answer), and **due** (`dueAt` at or before now).

