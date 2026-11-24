
**Decision**: The component reports `onSortChange` and renders `rows` as given, rather than sorting internally.
**Rationale**: Keeps sorting policy with the data owner rather than duplicating it inside the table.
**Approved**: pending

**Decision**: Selection is a capability, not a mandate — omitting `selectedIds`/`onSelectionChange` turns the same grid into an action-list table.
**Rationale**: Sites never fork a second table for rows whose interaction lives entirely in per-cell controls (admin's users/flags/feedback/api-tokens lists).
**Approved**: pending

**Decision**: The anchor id used for range selection is internal state, not part of the public API.
**Rationale**: It is only ever used to compute shift-click ranges and has no meaning to a caller.
**Approved**: pending

**Decision**: Row activation is a separate act from selection — click selects, double-click (or Enter) activates.
**Rationale**: Lets one table support multi-select (bulk actions) and row opening (a details view) without the two conflicting.
**Approved**: pending

**Decision**: Reordering is opt-in (`reorder`) and independent of sorting; the component does not itself disable reordering when a sort or filter is active.
**Rationale**: A dragged row's new position would describe the filtered/sorted view rather than the underlying list, so reordering while sorted is misleading — but enforcing that is a caller obligation the component leaves to the caller, who simply omits `reorder` when a sort or filter is in force.
**Approved**: pending

**Decision**: The table does not hijack keyboard or pointer events from in-cell controls (inputs, selects, buttons, contenteditable), and a click on such a control moves a single-row selection to that row but leaves a multi-row selection alone.
**Rationale**: A details-pane list (at most one row selected) needs "click into a cell moves the pane to that row" so the row stays inline-editable without losing selection sync; a bulk-action table (many rows selected) needs the opposite — moving the selection to one row on an incidental control click would silently turn a 30-row bulk action into a 1-row one. Guarding on `selectedIds.size > 1` serves both without either use case losing anything.
**Approved**: pending

**Decision**: With `autoSizeColumns: true`, the component renders once at `max-content` (measuring each cell), then locks in explicit widths for a second pass.
**Rationale**: Each row is its own grid, so a single `max-content` pass would size every row independently and the header would not align with the body. Both passes complete before paint, so no misaligned frame is ever visible.
**Approved**: pending

**Decision**: Column auto-sizing, drag-resize, persistence, and row reorder are kept as internal behavior of `DataTable` rather than split into separate hooks or wrapper components.
**Rationale**: Both features build on state the table already computes once per render — `ids` and `renderedColumns` — that reorder's `SortableZone`/`SortableSurface` and the auto-size measuring pass both read directly. Extracting either into a standalone hook or wrapper would mean re-threading that same state across a new boundary for every consumer, in exchange for splitting up a table that, as built, has one render pass and one set of derived ids to keep in sync.
**Approved**: pending

