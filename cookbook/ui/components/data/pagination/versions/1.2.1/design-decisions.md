
**Decision**: Pagination is fully controlled — `page`, `totalPages`, and `onPageChange` are all inputs.
**Rationale**: The pager renders the host's truth and requests a change, so it stays in lockstep with URL/query state the host already tracks instead of forking a second counter.
**Approved**: pending

**Decision**: The component renders `null` at `totalPages <= 1` rather than leaving that check to the host.
**Rationale**: Collapsing itself when there is a single page means every call site is just `<Pagination …/>` with no surrounding `{totalPages > 1 && …}`, so the visibility rule lives in exactly one place.
**Approved**: pending

**Decision**: `Prev`/`Next` are disabled at the bounds (`page <= 1`, `page >= totalPages`) rather than clamping the emitted page number.
**Rationale**: Disabling at the edges means an out-of-range request can't be issued at all; the component trusts the host to keep `page` in range rather than second-guessing it.
**Approved**: pending

**Decision**: Use a two-button `Prev`/`Next` pager with a `Page X of Y` caption rather than a numbered page strip.
**Rationale**: This stays compact and predictable for the list surfaces it serves, avoiding the layout churn of a windowed page-number row.
**Approved**: pending

**Decision**: Compose the shared `Button` (outline/sm) for both controls rather than building bespoke buttons.
**Rationale**: The pager inherits the family focus ring, disabled treatment, and press feel for free.
**Approved**: pending

