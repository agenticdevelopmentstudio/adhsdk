
**Decision**: Duplicate validation happens in-component, before `onRename` is called, as a UX guard; the host or server SHOULD also enforce uniqueness.
**Rationale**: The duplicate check runs before the async `onRename` call, so a user who types a taken name is corrected while they can still see what they typed, instead of a generic CRUD update — which takes no uniqueness lock — creating a duplicate that breaks every read keyed on the name. The check is racy by nature (another client can take the name between the check and the save), so it cannot be the only guard.
**Approved**: pending

**Decision**: The component holds the last non-null `node` rather than reading the prop directly.
**Rationale**: If the component unmounted the instant `node` became `null`, the Dialog's `open → false` exit transition would be cut off before it started. Holding the last non-null value one render longer lets the transition finish.
**Approved**: pending

**Decision**: The input text is seeded only when `open` becomes `true` with a non-null `node` — not on every `node` change.
**Rationale**: Seeding on every `node` change would overwrite in-progress edits whenever the host swaps `node` mid-edit.
**Approved**: pending

**Decision**: The duplicate check compares names case-insensitively, but the error message displays the user's typed name exactly as entered, not a normalized version.
**Rationale**: Case-insensitive comparison catches near-duplicates like "inventory" vs. "Inventory" across different nodes, while echoing the user's own input keeps the error message trustworthy. This does not prevent a case-only rename of the node's own name — "inventory" → "INVENTORY" still calls `onRename`, since it differs from the case-sensitive check in **reject-unchanged-name** and is excluded from the duplicate check by node id (see the corresponding edge case). Note also that lowercasing is a locale-sensitive transform (for example, Turkish's dotless "ı"); ports to other platforms should use the platform's locale-aware lowercasing for this comparison, not an invariant-culture call.
**Approved**: pending

**Decision**: Enter, handled by the input's key handler, commits the form; Escape is handled by the dialog primitive itself, not by the input.
**Rationale**: This matches the common web dialog pattern where the primary field commits on Enter and the container owns Escape-to-close.
**Approved**: pending

**Decision**: Submitting without changing the name closes the dialog via `onClose()` — the early return when the trimmed input equals `node.name` — without calling `onRename`.
**Rationale**: This avoids a no-op server round-trip for a rename that would change nothing.
**Approved**: pending

**Decision**: The duplicate error message includes the user's attempted name in quotes.
**Rationale**: This lets the user see exactly what they tried to use.
**Approved**: pending

