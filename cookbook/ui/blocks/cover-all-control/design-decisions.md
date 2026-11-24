
**Decision**: Each half is disabled, not hidden, when pressing it would change nothing.
**Rationale**: The source comment states that each half is enabled only when clicking would visibly change the stack, and the stack decides; keeping both buttons in place stops the toolbar from shifting as the stack changes.
**Approved**: pending

**Decision**: The control takes its two flags and callbacks from the host and holds no state.
**Rationale**: Whether a list is covered, and how many lists are open, is the stack's knowledge: the consumers compute `canCollapseAll` and `canExpandAll` from the covered state of each list, so the control stays a pure view of those two facts.
**Approved**: pending

**Decision**: The `<<<` glyph is three overlapped lucide chevrons instead of an icon.
**Rationale**: The source comment states that lucide has no triple chevron, so the glyph is composed from three overlapped chevrons, pulled back by 8px each.
**Approved**: pending

