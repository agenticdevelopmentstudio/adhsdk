
**Decision**: Use `messageIndex` as the React key instead of the array index.
**Rationale**: Keying on `messageIndex` preserves each DetailPane instance's identity across reorders of `visibleTopicIndexes` when the indexes resolve to distinct `messageIndex` values, maintaining focus and internal state; array-index keys would remount panes whenever the order changes. The guarantee depends on the distinct-indexes precondition in the **duplicate-indexes** edge case.
**Approved**: pending

**Decision**: The root div carries no ARIA role, by design.
**Rationale**: The stack is a layout wrapper and delegates all content semantics to its DetailPane children; adding a `group` role without a meaningful label would add noise for assistive technology (see Compliance: `semantic-markup`).
**Approved**: pending

**Decision**: When a topic does not exist at a given index, render nothing (null) rather than an error placeholder.
**Rationale**: This allows parent components to control error handling and prevents cascading errors if index arrays become stale.
**Approved**: pending

**Decision**: The root div's ref is exposed to the parent (see **forward-ref**); the mechanism, `forwardRef` or a `ref` prop, is a platform choice recorded in Platform Notes.
**Rationale**: Allows parent components to measure, scroll, or manipulate the container directly.
**Approved**: pending

