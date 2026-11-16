
- **Null and empty input**: An empty selector list removes the style
  element (MUST, see `empty-removes-style`). A pane with no address gets
  only entries whose site is `*`, as the store answers.
- **Boundary values**: A selector the engine rejects is skipped alone
  (MUST, see `bad-selector-isolated`); a selector containing quotes,
  braces or a closing script tag is carried as JSON data (MUST, see
  `selectors-as-json`).
- **Concurrent access**: The store answers off the main thread; its answer
  is applied on the main thread. When a change and a navigation race, the
  last selectors computed for the pane's current address are the ones that
  stand: a store-change refresh that supersedes the navigation's read
  makes the navigation read again, and after three superseded reads a
  last read that nothing can supersede decides; if that read fails the
  new document starts with no user-list rules, so it never starts on the
  old site's rules.
- **Error states**: If the store cannot be read, the renderer leaves the
  page as the last applied rules drew it and logs the failure; a failure
  here never shows content to the agent, which goes through its own
  fail-closed gatekeeper.
- **Offline or disconnected state**: Not applicable — the renderer reads a
  local store and styles the page in memory.
- **Missing file or unreachable server**: Not applicable — handled by the
  store.
- **Cancellation and timeouts**: A live apply that fails (the page went
  away mid-evaluation) is dropped; the next navigation's document-start
  script installs the current rules.
- **Items that re-render often**: Ads and other content a page rebuilds
  under new class names may escape a "this item" selector and reappear; the
  picker shows a one-time notice saying so.
- **Frames**: Whether the style also goes into subframes is a builder's
  choice (see Design Decisions).

