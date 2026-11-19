
- **Null/empty input**: Setting the panel list to `[]` MUST leave the
  sidebar with no sections and no rows, with no crash. Setting the search
  query to `""` MUST match every panel (see **empty-query-inclusion**).
- **Boundary values**: Index-based selection, visibility querying, and the
  internal row-id resolver MUST behave correctly at the first (`0`) and
  last (`count - 1`) valid indices, and MUST silently no-op (rather than
  trap) for any index outside that range, since each guards against
  out-of-bounds access before acting. The no-op emits no log line and no
  assertion; that silence is recorded as an open Design Decision.
- **Concurrent access**: Not a runtime race condition to defend against —
  the component's state is confined to a single, serialized execution
  context by construction, so simultaneous mutation of the panel list,
  search query, or selection callback from multiple threads is rejected at
  compile time; the source adds no additional locking because none is
  needed.
- **Error states**: Not applicable — setting the panel list, the search
  query, and index-based selection are synchronous, always-succeeding,
  in-memory operations with no fallible dependency (no network, disk, or
  database call) anywhere in this component.
- **Offline/disconnected state**: Not applicable — no networking of any
  kind appears anywhere in this component.
- **Query with repeated whitespace**: A search query containing multiple
  consecutive spaces (e.g. `"a  b"`) MUST narrow the same way a
  single-spaced query does — splitting on the space character omits empty
  pieces, so extra spacing does not introduce a term that trivially matches
  everything. Only the space character separates terms (see
  **all-terms-match**): a tab or newline inside the query stays part of a
  term.
- **Panel with a blank title**: A panel whose descriptor title is `""`
  renders a row with an empty label; this component performs no
  validation or fallback text for a blank title.
- **Descriptor mutated after the panel list is set**: A change to the
  title or subtitle of a listed panel's descriptor rebuilds the sections
  (see **descriptor-change-rebuild**); the rebuild runs on the UI thread's
  next turn, and several such changes in one turn rebuild once. A
  descriptor's icon, disabled flag, section, and heading are observable
  too, but this component does not subscribe to them, so a change to any
  of those leaves the row (or its section header) stale until some later
  panel-list, search-query, title, or subtitle change triggers a
  rebuild.

