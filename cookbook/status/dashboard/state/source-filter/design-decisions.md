
**Decision**: Start with every source selected, and allow the selection to become empty.

**Rationale**: The source is documented as starting with all sources selected, toggling one adds or removes it. No minimum is enforced. The activity panel keeps the result usable by bypassing the filter when only one source exists, and by letting through rows that have no platform.

**Approved**: pending

**Decision**: The selection is persisted per pane under a caller-supplied storage key.

**Rationale**: The source delegates to a shared persisted-state hook, the same one the sibling Environment Filter follows, so each pane's choice survives a reload. It was in-memory only in an earlier version of this spec, and that is no longer the case. The first render shows the default and storage is read afterwards, so a server render and the first paint agree.

**Approved**: pending

**Decision**: Extract the toggle into a shared concept even though only one pane uses it today.

**Rationale**: The source is documented as existing so the three panes can't drift in how they filter, naming active problems, recently resolved and activity. In the given source only the activity panel imports it, so the documentation describes the intended set of consumers, not the current one. Source Filter's own contract is unaffected.

**Approved**: pending

**Decision**: The toggle operation is not memoised.

**Rationale**: The source defines it as a plain function created on each render. Its one consumer passes it only to interaction handlers, never to a dependency list, so the changing identity has no observable effect there.

**Approved**: pending

