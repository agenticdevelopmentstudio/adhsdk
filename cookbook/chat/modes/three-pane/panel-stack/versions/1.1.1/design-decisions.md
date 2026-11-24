
**Decision**: Use `messageIndex` as the React key instead of the array index.
**Rationale**: Keying on `messageIndex` preserves each DetailPane instance's identity across reorders of `visibleTopicIndexes` when the indexes resolve to distinct `messageIndex` values, maintaining focus and internal state; array-index keys would remount panes whenever the order changes. This guarantee does not extend to the **duplicate-indexes** edge case, where repeated `messageIndex` keys leave React's reconciliation to decide which instance survives a reorder.
**Approved**: pending

**Decision**: When a topic does not exist at a given index, render nothing (null) rather than an error placeholder.
**Rationale**: This allows parent components to control error handling and prevents cascading errors if index arrays become stale.
**Approved**: pending

**Decision**: Forward the root div ref via `forwardRef`.
**Rationale**: Allows parent components to measure, scroll, or manipulate the container directly.
**Approved**: pending

