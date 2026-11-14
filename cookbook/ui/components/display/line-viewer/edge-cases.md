
- **Null / empty input**: No data source or no rows draws only the background; copy is disabled.
- **Boundary values**: A run range past the end of its row is clipped to the row; a run of zero length draws nothing. A click below the last row selects nothing. A gutter value wider than its column is left-aligned and clipped. A slice boundary that falls inside a surrogate pair or composed sequence widens to include all of it.
- **Concurrent access**: Main actor only; the data source is asked on the main thread during drawing.
- **Error states**: None: the viewer draws whatever rows it is given.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: Not applicable: drawing is synchronous and bounded by the visible rows.

