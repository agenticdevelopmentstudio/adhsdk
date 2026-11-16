
- **Null and empty input**: No query lists recent visits (MUST, see
  `all-reads-store`); an empty history is a reply, not a failure (MUST, see
  `reply-lines`, agent-history-tool-018). An empty back/forward list
  likewise.
- **Boundary values**: `limit` absent or above 200 (MUST, see
  `limit-default-and-cap`, agent-history-tool-010); below 1 is the
  builder's choice (Design Decisions).
- **Concurrent access**: The setting is read at the time of the call (MUST,
  see `effective-access-per-pane`); a change while a call runs takes effect on
  the next call. The back/forward list is read on the main thread.
- **Error states**: None, closed privacy, paused, hidden or closed panes each
  refuse with their own sentence (MUST, see `none-refuses-with-reason`,
  `closed-privacy-refuses`, `same-access-checks`).
- **Offline or disconnected state**: Not applicable — history is local.
- **Missing file or unreachable server**: A history store that cannot be
  opened under All history fails with the tool set's usual error sentence,
  concealed like every other error reply.
- **Cancellation and timeouts**: Not applicable — one bounded read.
- **Escaped privacy words**: A privacy word hidden in an address's
  percent-escaped or `+`-escaped form is still concealed (MUST, see
  `conceal-url-forms`, agent-history-tool-013).
- **Local files**: A `file:` visit is never listed, in the back/forward
  list or the store (MUST, see `no-local-files`); the store leaves them out
  in its query so a limit of 50 still lists 50 visits the agent may see.
- **Words scoped to another site**: A privacy word scoped to one site is
  concealed on every line, including the lines of other sites and when the
  page in front is on a site the word does not apply to (MUST, see
  `conceal-with-every-word`).
- **Private browsing**: A pane browsing privately records no visits, so All
  history never contains its pages; Current tab only still reads the tab's
  own back/forward list, which the person can already see.

