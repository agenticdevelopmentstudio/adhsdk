
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
  on the page's main thread through the browser engine; the decode, the
  tree build and the concealment of its payload run off the host's main
  thread, so a large page costs no frames. Two walks of one page each
  produce their own reference generation, as snapshots do today.
- **Error states**: Every error — walker error, timeout, undecodable
  payload, unreadable or conflicting privacy words — collapses to the one
  unavailable page with a reason beginning `Agent view unavailable: `
  (MUST, `fail-closed-on-walker-failure`, `fail-closed-on-vault`). An
  agent-list selector the page cannot evaluate is one of them: the walk is
  refused and the page is unavailable (MUST,
  `invalid-exclude-selector-fails-closed`).
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
  records the cheaper structural path (`html > body > tag:nth-of-type(n) >
  …`) for every node after the share is spent, so a large page finishes
  where today's snapshot does. That path is stored as an agent-list entry,
  so it MUST keep naming its element when the host's own `<style>`
  elements come and go: `body` takes no index and every other step counts
  only siblings of its own kind. Selectors never decide exclusion: the agent list is
  evaluated before the walk, and a selector it cannot evaluate refuses the
  walk, as `invalid-exclude-selector-fails-closed` says.
- **The page root on the agent list**: The walk starts beneath `body`, so
  an agent-list entry matching `html` or `body` (or a hidden `body`) is
  checked before it: the agent gets the empty document with an empty
  title, whatever scope it asked for, and no reference into the page
  resolves (MUST, `walker-skips-agent-list`, `withheld-refs-stale`).
- **A withheld option**: A select's value is its first selected option
  the agent may see, so an option on the agent list (or hidden, or in a
  withheld group) never reaches the agent as its select's value, and the
  select action answers a withheld option's value or label exactly as one
  that names nothing (MUST, `walker-skips-agent-list`).
- **Privacy words change mid-read**: The concealment in force when the
  build starts conceals the whole result; the tool reply is concealed
  with the start and end words together, per
  `reply-concealed-with-start-and-end-words`.
- **Excluded ancestor of focus or scope**: See `scope-within-walk` and
  `titles-dialogs-focus-through-string-path` — content under an excluded
  ancestor never reaches the agent by either path; a withheld scope gives
  the whole page, the same answer as a scope that names nothing.
- **Refs after the agent list grows**: Only a walk hands out references,
  and it never gives one to an excluded element. Any change to the
  hidden-items store makes every reference stale at once (a new generation,
  the reference table cleared), and a reference to an element a later walk
  withheld resolves as stale, whichever walk handed it out, so an element
  excluded mid-session is never acted on through an older reference (MUST,
  `withheld-refs-stale`).
