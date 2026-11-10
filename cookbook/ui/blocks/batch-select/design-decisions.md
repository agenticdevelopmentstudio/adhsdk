
**Decision**: Selection is cleared on both entry and exit of batch mode.
**Rationale**: Clearing on exit prevents an invisible selection after toggling off. Clearing on entry ensures a fresh batch interaction does not inherit selections from a prior single-select interaction. This prevents accidentally acting on rows a user has reason to believe were deselected.
**Approved**: pending

**Decision**: The `resetKey` reset happens synchronously during render, not in an effect.
**Rationale**: An effect-based reset would allow one render to commit with stale selections against new rows (e.g., after filtering or paging). The render-time reset via `React.useRef` ensures that by the time `selectedIds` is visible to the caller, it already reflects the current `resetKey`.
**Approved**: pending

**Decision**: `resetKey` comparison uses `Object.is`.
**Rationale**: This permits primitives (page number, search string) to be passed directly without rebuilding. Passing non-primitives (rebuilt objects or Sets) causes a reset on every render; this is a caller error, not a hook error. See **resetKey as non-primitive**.
**Approved**: pending

**Decision**: Render-time reset clears `selectedIds` to a shared `EMPTY_SELECTION` instance rather than a freshly constructed empty `Set`.
**Rationale**: A shared reference prevents caller effects and memos from being invalidated by render-time resets; a freshly constructed empty `Set` on each reset would look like a new value to consumers and cause unnecessary re-computation. See **reset-uses-shared-empty-selection**.
**Approved**: pending

