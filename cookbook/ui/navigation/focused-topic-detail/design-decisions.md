
**Decision**: Compose existing blocks only and leave the focused pane's content to the consumer.
**Rationale**: The source comment says anything inside the focused detail pane is an implementation detail of the pane, not of the frame, so the frame stays reusable across item kinds.
**Approved**: pending

**Decision**: Fall back to the All view for an unknown `focusedId`.
**Rationale**: The source comment prefers it to an inconsistent half-focused frame, for example when the focused item was deleted.
**Approved**: pending

**Decision**: Key the focused content by `focusedId`.
**Rationale**: The source comment wants a focus switch to remount the pane so form and draft state start fresh.
**Approved**: pending

**Decision**: Make the pane edge-to-edge and give the block's own rows their inset.
**Rationale**: The source comment says consumer content such as a button bar then spans the full pane without negative-margin hacks.
**Approved**: pending

