
- **Empty topics array**: When `topics` is empty and `visibleTopicIndexes` contains indexes, component MUST render the root div with no DetailPane children.
- **Empty visibleTopicIndexes array**: When `visibleTopicIndexes` is empty, component MUST render only the div container with no child DetailPane components.
- **Out-of-bounds indexes**: When `visibleTopicIndexes` contains indexes greater than or equal to `topics.length`, component MUST skip those indexes and render nothing for them.
- **Negative or non-integer indexes**: `topics[idx]` resolves to `undefined` for a negative or non-integer `idx`, since JavaScript array indexing has no entry for such a key. Component MUST skip those indexes the same way as out-of-bounds indexes.
- **Undefined topic**: When a topic at a given index is undefined or null, component MUST render nothing (null return from map function).
- **Duplicate indexes**: When `visibleTopicIndexes` contains the same index multiple times, component MUST render multiple DetailPane instances for that topic (one per appearance in the array). Because each instance is keyed on the same `messageIndex` (see **use-message-index-as-key**), this violates React's key-uniqueness expectation: React logs a duplicate-key warning, and which sibling instance keeps its mounted identity across a subsequent reorder is left to React's reconciliation, not guaranteed by this component.

