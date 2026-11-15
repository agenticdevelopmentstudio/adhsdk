
- **Null and empty input**: A pick with no This item selector is refused
  (MUST, see `pick-without-selector-refused`). A page with no address
  saves entries with site `*`, as the shared default rule says. An empty
  list shows the popover with an empty table.
- **Boundary values**: An All items like it selector matching exactly half
  of the page's elements is allowed; one more is not (MUST, see
  `loose-selector-disabled`). A selector that matches `body` or `html`
  counts every element and is therefore refused. A label is cut at 60
  characters.
- **Concurrent access**: The page may change between the click and OK;
  the selectors saved are those computed at click time. Two panes may
  each run selecting mode; they share the store, and each pane's popover
  shows the store's current list.
- **Error states**: If the picker script fails to install (the page went
  away, or WebKit refuses the evaluation), selecting mode does not start,
  the button stays in its idle state, and the failure is logged. Finder
  throwing for one element refuses that pick only.
- **Offline or disconnected state**: Not applicable — the picker works on
  the page in memory and a local store.
- **Missing file or unreachable server**: Not applicable — the store's
  concern.
- **Cancellation and timeouts**: Every exit path (stop, Esc, `cancel`,
  navigation, tab switch, close) goes through one end routine that
  removes the outline, listeners and handler and clears the preview (MUST,
  see `stop-cleans-up`).
- **Frames and shadow roots**: The picker runs in the main frame. An
  element inside a cross-origin frame cannot be reached; clicking the frame
  picks the frame element itself. An element inside a shadow root may get
  no unique document selector and is then refused.
- **Pages that re-render**: An item the page rebuilds under new class
  names may escape its selector and reappear; that is what the first-use
  notice warns of.

