
**Decision**: Row selection persists when filters change; the hidden count in the bar shows how many selected rows are currently off-screen rather than clearing them.
**Rationale**: Preserves operator intent — a bulk action targeting three rows remains valid even if a search temporarily hides one of them. The hidden count informs the operator, and the clear-selection button offers a one-press undo.
**Approved**: pending

**Decision**: The details pane always shows exactly one row's data, prompting the operator to select a single row when zero or several are selected.
**Rationale**: A pane is a view of a record, and there is no such thing as "the details of three rows." This avoids the ambiguity of "which row's details?" and keeps the pane's data source unambiguous.
**Approved**: pending

**Decision**: Rows carry no action buttons of their own; every action lives in the bar and operates on the selection, except for the rare per-row control (a role menu, a membership chip) supplied as a column by the parent.
**Rationale**: Per-row buttons duplicate the bar's actions and create confusion about whether an action applies to one row or the whole selection.
**Approved**: pending

**Decision**: The component never paginates; the full matching set stays on screen and scrolls.
**Rationale**: Pagination plus filtering creates two ways to not see a row — a filter that matches 40 items and a pager showing 25 hides 15 behind a control most operators never press.
**Approved**: pending

**Decision**: Whether the entire list is replaced by an error alert depends on whether any rows currently exist (and whether the list is still loading), not on loading state alone.
**Rationale**: If the list has never loaded, the empty state's "nothing here" claim has no standing coming from a failed request, so the whole UI is replaced — unless a load is still in flight, in which case replacing it would hide the very loading indicator that explains why there are no rows yet. If a refetch fails after an earlier success, the rows on screen are still real — just possibly stale — so they stay visible with an error strip above them; this prevents a transient network failure from blanking out rows the operator just acted on.
**Approved**: pending

**Decision**: Search persists independently of selection — the search input is a controlled input wired to the controller's `search`/`setSearch`, but typing in it, or changing a filter, never clears the current selection.
**Rationale**: The search term is an independent dimension of list state; conflating "what's visible" with "what's selected" would silently drop a selection made a keystroke before a filter narrowed the view.
**Approved**: pending

