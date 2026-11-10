
- 0 selected → `emptyDetail`; exactly 1 → `renderDetail`; >1 → the multi-select
  hint.
- A filter matching no rows shows the table's `emptyLabel`, while the selection
  of rows no longer visible is retained (see **own-selection**: ids are pruned
  only when a row leaves `rows`).
- `loading` → the `DataTable` loading state (see **forward-loading-state**);
  empty data → `emptyLabel`.
- On delete confirm, the component clears its entire selection immediately and
  synchronously in the confirm handler (and the URL parameter, if `paramKey` is
  set) — see **confirm-delete**. It does not wait for the caller's `rows` prop
  to update first; the passive pruning in **own-selection** only applies to ids
  removed some other way.
- When `onDelete` is not provided, no Delete button is rendered (see
  **omit-delete-without-handler**).
- When `paramKey` is provided but the URL parameter points to a row no longer in
  `rows`, the parameter is cleared and selection is empty (fail-safe to
  "nothing open") — see **clear-stale-deep-link**, which withholds this while
  `loading` is `true`, and also withholds it whenever `rows` is empty (even with
  `loading` false, or never supplied), so an async row load never clears a valid
  link before its data arrives.
- When both `paramKey` and a controlled `filterText` are provided, the initial
  URL-seeded selection is restored on mount regardless of `filterText`: the
  filter only narrows what `DataTable` renders, never the selection itself, so
  order between the two never matters.
- The layout floor (`min-h-[16rem]`) ensures that when a container is
  over-constrained, the page's own scroll takes overflow and rows remain
  hit-testable (without the floor, the split compresses to 0 and rows become
  unclickable despite appearing in layout).

