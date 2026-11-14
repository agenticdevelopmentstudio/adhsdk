
**Decision**: The view tells the card its height after layout, rather than pinning the card's bottom.
**Rationale**: The card owns a height constraint on its table, so a pinned bottom would fight it; setting the table height keeps the card's own sizing in charge.
**Approved**: pending

**Decision**: The view asks only for a minimum height, not the card's current height.
**Rationale**: A minimum equal to the card's height would let the view grow but never shrink, because the slack could never go negative.
**Approved**: pending

**Decision**: Differences of half a point or less are ignored.
**Rationale**: Fractional frames would otherwise change the height, trigger layout and change it again.
**Approved**: pending

**Decision**: The view is a separate container, not a mode of the card.
**Rationale**: Only owners whose card fills a resizable window need it; the card stays reusable in a scrolling pane.
**Approved**: pending

