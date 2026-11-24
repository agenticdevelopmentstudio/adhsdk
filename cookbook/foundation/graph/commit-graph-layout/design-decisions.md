
**Decision**: The first parent joins a slot to its left that already expects it, rather than always inheriting the commit's slot.
**Rationale**: A branch that forks from a commit already on the main line rejoins it at once, which keeps the graph narrow and the main line in column 0.
**Approved**: pending

**Decision**: First-parent edges carry the commit's lane; further-parent edges carry the lane of the slot they reach.
**Rationale**: A line keeps its colour until it ends, and a merge edge is drawn in the colour of the branch it brings in.
**Approved**: pending

**Decision**: Lanes come from a counter that only increases.
**Rationale**: A colour index is never reused while the layout lives, so two lines that are both visible never share an index by reuse; the view maps the index onto its palette.
**Approved**: pending

