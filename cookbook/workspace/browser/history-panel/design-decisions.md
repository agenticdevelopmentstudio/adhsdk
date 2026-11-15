
**Decision**: The panel takes a list model and an open callback and nothing
else; the window composes it.
**Rationale**: The design makes the panel reusable and keeps hosting it in
the projects window's shelf open for later (a non-goal now). A panel that
knows its window could not be dropped into another host without change.
**Approved**: pending

**Decision**: The list model, not the panel, owns filtering, trimming and
reload coalescing.
**Rationale**: It keeps the behavior testable without a view (the plan's
model tests) and lets any host reuse the same rules.
**Approved**: pending

**Decision**: Coalescing is the builder's to implement — a generation
counter checked when a reload answers, or cancelling the previous reload
task — so long as `latest-filter-wins` holds.
**Rationale**: Both satisfy the requirement; the design names only the
outcome.
**Approved**: pending

**Decision**: Whether the remove button draws disabled when nothing is
selected, the exact SF Symbols, the window's default and minimum sizes,
and the confirmation sheet's wording are the builder's.
**Rationale**: The design leaves symbols and dialog sizes to the builder
and specifies only the buttons, their tooltips and that clearing confirms.
**Approved**: pending

**Decision**: How a store failure is reported (a log line, an alert, or
leaving the list unchanged) is the builder's, provided the list never shows
a visit as removed when it was not.
**Rationale**: The design does not specify error presentation.
**Approved**: pending

**Decision**: The recording gate is one pure function of the Record
history setting and the pane's private browsing state, and every record
call goes through it.
**Rationale**: One code path means private browsing cannot be bypassed by
a second record call that forgot to check it, and the gate is testable on
its own.
**Approved**: pending

