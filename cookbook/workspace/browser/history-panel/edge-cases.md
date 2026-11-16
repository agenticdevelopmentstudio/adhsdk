
- **Null and empty input**: An empty or whitespace-only filter lists recent
  visits (MUST, see `filter-is-trimmed`, history-panel-004). An empty store
  lists nothing and shows no empty-state text (MUST, see
  `panel-no-inline-help`). Removing an empty selection removes nothing.
- **Boundary values**: Results never exceed the page size, recent or
  filtered (MUST, see `list-is-bounded-by-page-size`). A filter containing
  the store's LIKE wildcards (`%`, `_`) or its escape (`\`) matches those
  characters literally, because the store escapes them.
- **Concurrent access**: Rapid typing issues overlapping reloads; only the
  latest filter's answer is shown (MUST, see `latest-filter-wins`). Debug
  builds may run several app copies sharing one history file; the store's
  one-writer WAL pool serializes their writes, and each copy's list shows
  the store as of its last reload. Within one copy, every write to the
  store reloads the list (MUST, see `reloads-on-store-change`), so a visit
  recorded while the panel is open appears without reopening it.
- **Error states**: A store read or write that throws leaves the listed
  visits as they were; how the failure is reported is the builder's (see
  Design Decisions). No error leaves a visit shown as removed when it was
  not.
- **Offline or disconnected state**: Not applicable — the history store is
  a local file; listing, filtering, removing and clearing need no network.
  Opening a visit hands an address to a browser, which handles its own
  connectivity.
- **Missing file or unreachable server**: If the history file cannot be
  opened, there is no store to build a list model on, and the host does not
  offer the panel; the store creates its file when it is first opened.
- **Cancellation and timeouts**: A superseded reload's answer is discarded
  (see `latest-filter-wins`). Every store statement runs under the store's
  own deadline, so a wedged file fails a call rather than hanging the
  panel.
- **Private browsing**: A private pane records nothing (MUST, see
  `private-browsing-never-records`), so the panel cannot list a private
  visit. Turning private browsing off does not back-fill visits made while
  it was on.

