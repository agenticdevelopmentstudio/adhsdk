
- **Null and empty input**: An empty document yields a page with a
  document root and no children (MUST, `built-up-not-trimmed`). A missing
  payload with no error is a malformed payload and yields the unavailable
  page (MUST, `fail-closed-on-walker-failure`). An empty string through the
  string path stays empty.
- **Boundary values**: A depth option of 0 or less is no limit, as in
  today's snapshot (MUST, `snapshot-tool-contract-unchanged`); a very
  large page is bounded by the walker's timeout, after which the page is
  unavailable, never truncated (MUST, `no-partial-content-on-failure`). An
  `href` with only a fragment resolves against the page address and is
  kept only if the result is `http`/`https`.
- **Concurrent access**: The builder is a value with no mutable state;
  concurrent builds from any thread MUST be independent. The walker runs
  on the page's main thread through the browser engine; two walks of one
  page each produce their own reference generation, as snapshots do today.
- **Error states**: Every error — walker error, timeout, undecodable
  payload, unreadable or conflicting privacy words — collapses to the one
  unavailable page with a reason beginning `Agent view unavailable: `
  (MUST, `fail-closed-on-walker-failure`, `fail-closed-on-vault`). An
  invalid agent-list selector is not an error: it is a warning and the
  walk continues (MUST, `invalid-exclude-selector-isolated`).
- **Offline or disconnected state**: Not applicable — the component reads
  only the already-loaded document and the local agent list; it makes no
  network request.
- **Missing file or unreachable server**: The agent list's store missing
  or unopened yields the unavailable page, as an unreadable list does: at
  runtime the shared store is absent only when its database could not be
  opened, and the agent list failing must not fail open (MUST,
  `fail-closed-on-walker-failure`). An empty list is no exclusions. The
  walker script missing from the bundle is a walker error and yields the
  unavailable page.
- **Cancellation and timeouts**: The walker stops after its timeout
  (default 1500 milliseconds) and the page is unavailable (MUST,
  `fail-closed-on-walker-failure`). A navigation during a walk makes its
  references stale under the existing generation rule.
- **Navigation between reading the list and walking**: The agent-list
  selectors are read for one address and the walk runs on whatever document
  is current. The walk reports the address it walked; when that differs from
  the address the list was read for, the walk stands only if the walked
  page's own enabled selectors are the ones applied. Otherwise the page is
  walked once more with its own list, and a page still changing after that
  is the unavailable page (MUST, `no-partial-content-on-failure`). One
  site's exclusions are never applied to another site's page.
- **Very large pages**: The selector each node records costs a search per
  node. The walker gives that search a share of its budget (a third) and
  records the cheaper structural path (`tag:nth-child(n) > …`) for every
  node after the share is spent, so a large page finishes where today's
  snapshot does. Selectors never decide exclusion: the agent list is
  evaluated before the walk, and a selector it cannot evaluate excludes
  nothing and is warned, as `invalid-exclude-selector-isolated` says.
- **Privacy words change mid-read**: The concealment in force when the
  build starts conceals the whole result; the tool reply is concealed
  again with the words of the moment it returns, as replies are today.
- **Excluded ancestor of focus or scope**: See `scope-within-walk` and
  `titles-dialogs-focus-through-string-path` — content under an excluded
  ancestor never reaches the agent by either path.

- **Refs after the agent list grows**: Only a walk hands out references,
  and it never gives one to an excluded element, so no action resolves a
  reference the agent page did not show. A reading walk (text, find,
  wait_for, the focused element) keeps the last snapshot's references, so
  an element excluded after that snapshot, by an agent-list entry added
  mid-session, keeps the reference that snapshot gave it until the next
  snapshot restarts the references and advances the generation.
