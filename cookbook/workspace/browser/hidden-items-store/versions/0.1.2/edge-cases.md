
- **Null and empty input**: A page with no address matches only entries
  whose site is `*` (MUST, see `site-wide-matching`, vector 005). A list
  with no entries for a page answers an empty list of items and an empty
  list of selectors, never an error. An entry with an empty selector is
  never stored: the picker refuses a pick with no selector before it reaches
  the store, and the store also refuses to add an entry whose selector is
  empty after trimming (a builder's choice, see Design Decisions).
- **Boundary values**: A site switch that has never been set reads as on
  (MUST, see `site-switch-defaults-on`). Many entries on one site are all
  returned; no cap is imposed by this component.
- **Concurrent access**: Several app copies (Debug builds) and several
  panes share one file. The store sits on the toolkit's bounded database
  pool (one writer, pooled readers, a deadline on every statement), so
  concurrent readers and a writer are safe; the last write wins for a site
  switch.
- **Error states**: A file that cannot be opened or a statement that fails
  or times out throws to the caller. The store never answers a failed read
  with a guessed list; what the caller does with the failure is the
  caller's concern (the agent gatekeeper fails closed). A file that cannot
  be opened at launch leaves the app with no store, a degraded mode rather
  than a launch failure.
- **Read during the launch open**: The launch open runs off the main
  thread; a read of the shared store before it finishes waits for it
  (awaiting, never blocking the main thread, for a caller that can run
  during launch) and gets the store, or no store if the open failed, never
  a premature no store (MUST, see `opened-at-launch`).
- **Offline or disconnected state**: Not applicable — the store is a local
  file and makes no network call.
- **Missing file or unreachable server**: A missing file is created, with
  its directory, on first open; deleting it loses both lists and every site
  switch and nothing else (MUST, see `standalone-file`).
- **Cancellation and timeouts**: Every statement runs under the database
  pool's deadline, so a wedged file throws rather than hanging the pane.
- **Site pattern edited after creation**: An entry's site is stored as
  text and matched at query time, so a page is matched against the current
  site pattern, never a cached host.

