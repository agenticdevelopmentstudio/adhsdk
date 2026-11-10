
**Decision**: The block owns selection as a `Set<string>` rather than the table
owning it.
**Rationale**: Selection must survive filtering and feed the toolbar actions
and details pane.
**Approved**: pending

**Decision**: Generic over row type `T`.
**Rationale**: Reusable platform-wide for any master/detail view of this shape.
**Approved**: pending

**Decision**: Delete always routes through a destructive `AlertModal` confirm.
**Rationale**: Deletion is destructive; a confirm prevents accidental loss.
**Approved**: pending

**Decision**: Filter is controlled-or-internal.
**Rationale**: Callers can drive or observe the query when needed, but the
common case requires no wiring.
**Approved**: pending

**Decision**: URL-driven selection is opt-in via `paramKey`.
**Rationale**: Deep-linking (via URL parameter) is a web pattern and not all
use cases need it; omitting `paramKey` preserves the legacy internal-state-only
behavior byte-for-byte. When provided, selecting a row mirrors the id to the
URL and reloading or sharing the link restores the open row without
remounting.
**Approved**: pending

**Decision**: `storageKey` persists split bar position only, not selection.
**Rationale**: Selection is ephemeral (the user opened a row to read it, not
to remember it forever); the split position is a layout preference worth
retaining. A separate `columnWidthsKey` persists column widths, orthogonal to
split position.
**Approved**: pending

