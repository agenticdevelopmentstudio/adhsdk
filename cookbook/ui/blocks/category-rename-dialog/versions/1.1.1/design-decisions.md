
**Decision**: Duplicate validation happens in-component, before `onRename` is called, rather than being left to the server.
**Rationale**: The duplicate check in `commit()` (the `taken` computation) runs before the async `onRename` call, preventing a generic CRUD update — which takes no uniqueness lock — from creating a duplicate and breaking every read that keys on the name.
**Approved**: pending

**Decision**: The component holds the `node` prop's value via `useLastPresent(target)` rather than reading `target` directly.
**Rationale**: If the component unmounted the instant `target` became `null`, the Dialog's `open → false` exit transition would be cut off before it started. Holding the last non-null value one render longer lets the transition finish.
**Approved**: pending

**Decision**: The `React.useEffect` that seeds the input text runs only when `open` becomes `true` with a non-null `target` — not on every `target` change.
**Rationale**: Seeding from `target` on every change, rather than only on open, would let a `target` update while the dialog is reopening on `null` restore stale text from the previous session.
**Approved**: pending

**Decision**: The duplicate check in `commit()` compares names with `.toLowerCase()` to ignore case, but the error message displays the user's typed name exactly as entered, not a normalized version.
**Rationale**: Case-insensitive comparison catches near-duplicates like "inventory" vs. "Inventory" across different nodes, while echoing the user's own input keeps the error message trustworthy. This does not prevent a case-only rename of the node's own name — "inventory" → "INVENTORY" still calls `onRename`, since it differs from the case-sensitive check in **reject-unchanged-name** and is excluded from the duplicate check by node id (see the corresponding edge case). Note also that `.toLowerCase()` is a locale-sensitive transform (for example, Turkish's dotless "ı"); ports to other platforms should use the platform's locale-aware lowercasing for this comparison, not an invariant-culture call.
**Approved**: pending

**Decision**: Enter, handled in the `Input`'s `onKeyDown`, commits the form; Escape is handled by the `Dialog` component itself, not by the input.
**Rationale**: This matches the common web dialog pattern where the primary field commits on Enter and the container owns Escape-to-close.
**Approved**: pending

**Decision**: Submitting without changing the name closes the dialog via `onClose()` — the early return in `commit()` when the trimmed input equals `node.name` — without calling `onRename`.
**Rationale**: This avoids a no-op server round-trip for a rename that would change nothing.
**Approved**: pending

**Decision**: The duplicate error message, set in `commit()`'s `taken` branch, includes the user's attempted name in quotes.
**Rationale**: This lets the user see exactly what they tried to use.
**Approved**: pending

