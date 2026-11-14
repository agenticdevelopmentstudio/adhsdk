
The one home for the "header above a list" pattern in `@adh-sdk/ui`
(`blocks/list-header.tsx`): a single row hosting an optional left-aligned title,
a filter text field (search icon, controlled value), a flexible space, and
right-aligned actions (e.g. a `+ New` button, Delete) — all inside the same
recessed `ButtonBar` strip every toolbar on the platform uses, so list headers
look identical everywhere.

Consumers:

- `ListWithDetailsPane` renders it above its `DataTable`.
- A `HierarchicalTopicDetail` level hosts it via the level's `headerSlot` (a
  pinned, non-scrolling strip between the level's title header and its rows), so
  entity lists inside the stack get the same filter + actions header.

Related, NOT absorbed: `SearchFilterBar` is the stacked search-plus-filter-axes
region (`role="search"`, `<select>` rows under the field) for full search pages;
`ListHeader` is the one-row list toolbar. They share the `Input` primitive.

