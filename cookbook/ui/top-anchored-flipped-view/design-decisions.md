
**Decision**: Flip the coordinate system rather than pin content to the top with constraints.
**Rationale**: AppKit positions a short document from the bottom; flipping it fixes every owner's content at once without constraints that fight the clip view.
**Approved**: pending

**Decision**: The view is empty and final.
**Rationale**: It exists only for the flip; any behavior belongs in the owner.
**Approved**: pending

