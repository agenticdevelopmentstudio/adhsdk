
**Decision**: The pane stays bare; `TopicRail` owns the header, toolbar, `+`, footer and close button.
**Rationale**: Keeps the primitive focused and gives every consumer the same chrome blocks (separation of concerns), and `TopicDetail` opts out of the titled header and toolbar by passing no `title`.
**Approved**: pending

**Decision**: Collapse is intrinsic, with both controlled and uncontrolled modes.
**Rationale**: Collapsing to an icon strip is a core site gesture; controlled mode lets the hierarchical stack auto-minimize ancestor rails.
**Approved**: pending

**Decision**: The rail measures its own intrinsic width (`max-content`, rows, header and toolbar) and reports it through `onFit`.
**Rationale**: Only the rail knows its row anatomy, and an intrinsic measure cannot oscillate with the width the parent hands back; the range is scaled by the document's real root font size, because a hard-coded 16px range was a third too generous at the family's 12px root. The measure is skipped while a query narrows the rows, since a width taken from the matches outlived the query.
**Approved**: pending

**Decision**: Every titled rail has a filter, and its default is an autocomplete that leaves the rows whole; `live` filters the rows instead.
**Rationale**: Rails are too narrow for a pinned field, so a panel pops over the toolbar; a picker dialog that drives the list from the field needs `live`. Highlight is kept by topic id so a late-arriving host list does not move it, and the selected row is offered only if it matches so Return cannot choose the topic already open.
**Approved**: pending

**Decision**: Filter keystroke quirks are handled explicitly: Escape stops at the field, Return calls `preventDefault` before focus moves, IME Return is ignored, and the clear button and suggestion list swallow `mousedown`.
**Rationale**: Each is a recorded bug: a dialog closing with the filter, Return re-opening the panel through the button's keypress, an IME candidate choosing a row, and Safari blurring the field and closing the panel before a click landed.
**Approved**: pending

**Decision**: The underline maps positions per character instead of searching the folded label.
**Rationale**: Case folding can change a label's length ("İstanbul"), which put the underline on the wrong letters.
**Approved**: pending

**Decision**: A link row is reported to `onSelect` by the list and run by the owner (`TopicDetail` does it via `topicLinkOf`); a flash id stands in for the selection for 1000ms.
**Rationale**: A link is never an entry of its own list, so without the flash the click would show nothing.
**Approved**: pending

**Decision**: The blocked dot rides the icon, with the standalone dot when icons are hidden, and the state is announced by text.
**Rationale**: Trailing slots are dropped in the strips, where a user hunting for a greyed-out Save most needs the marker; colour alone is not a signal.
**Approved**: pending

**Decision**: Ticking a batch checkbox is independent of selecting a row, and the checkbox is a sibling of the row button.
**Rationale**: A checkbox cannot nest in a button, and acting on rows other than the open one must not close its detail.
**Approved**: pending

**Decision**: Covered lists are pure-select, uncovered lists re-fire `onSelect` on a re-click.
**Rationale**: Covered rows are peeking siblings with no dismiss affordance; the uncovered owner decides whether a repeat means toggle-off.
**Approved**: pending

**Decision**: Prefetch uses one dwell timer per list and never arms on the selected row.
**Rationale**: A per-row timer would arm several during a sweep, and re-reading the open row spins its own list behind the pane.
**Approved**: pending

**Decision**: A failed `onDelete` leaves the dialog open and the error to the caller.
**Rationale**: The caller knows the failure and its wording; the dialog stays so the user can retry or cancel.
**Approved**: pending

**Decision**: Every row is guaranteed an icon, and `preview` is clamped through a lookup table with a number clamp.
**Rationale**: The icon strip must never show a blank slot; Tailwind only generates classes it sees written out, and `previewLines` comes from a user setting, so an out-of-range number would silently print the whole note.
**Approved**: pending

**Decision**: `description` and `leadsTo` stay on the shared item type though this file never reads them.
**Rationale**: One row shape serves surfaces that show a blurb and the cascading view's hold logic, so a host does not map between shapes.
**Approved**: pending

**Decision**: Technical debt: the source documents `TopicList` and `rowExitEl` with a doc comment block left over above `rowExitEl` that belongs to `TopicDetail`, and keeps two copies of the width-constant comment.
**Rationale**: Noted so implementers do not treat the stray comment as a requirement; no behavior depends on it.
**Approved**: pending

