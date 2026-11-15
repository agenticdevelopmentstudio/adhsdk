
This logic is "The ONE row model" of the status dashboard. Active problems, recently-resolved rows and the activity feed are all built into a single row shape, then rendered by one status row view through the display adapter, "so every pane has identical row capabilities (clickable commits, consistent links) and a new field is added in one place".

This logic provides:

- **Tone** and **the row shape** — the row's data shape.
- **The problem-to-row builder** and **the activity-to-row builder** — spell a server-derived problem or activity row (specified in Board Types) as a row. "The server has already decided what is a problem, what happened, and when — these builders only spell the row."
- **The display adapter** — maps a row, plus the current time, to the status row view's rendering props.
- **The search-text function** — the free text the pane filter boxes match against.
- **The row-text function** and **the rows-text function** — clipboard serialization, one tab-separated line per row (used by the activity panel view's copy button).
- **The commit-URL function** — a GitHub commit URL or null.
- **The state-label table** — the problem state to status-word table.
- **No freshness clock**: this logic never judges how old a row is. The server states an unconfirmed phase as verb `"unknown"`, tone `"stale"`, and supplies each deploy's `unconfirmedAt` deadline (read by the deploy view logic).

Every export is pure and synchronous. This logic performs no I/O, holds no state, and is covered by the implementation's test suite (see Platform Notes).

