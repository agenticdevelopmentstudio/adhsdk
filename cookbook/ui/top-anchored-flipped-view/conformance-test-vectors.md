
No test beside the source exercises this view. These vectors are derived from
the source and untested.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| top-anchored-001 | flipped-origin | Create the view and read `isFlipped` | True |
| top-anchored-002 | content-at-top | Subview 100 points tall pinned to the top of a document view; the scroll view's visible area 400 points tall | The subview's top edge is at the top of the visible area |
| top-anchored-003 | content-at-top | Same, using an unflipped view as the document | The subview sits at the bottom, which is the case this view prevents |
| top-anchored-004 | no-drawing | Render the view alone | Nothing is drawn |
| top-anchored-005 | container-only | Create the view and read `subviews` and `constraints` | Both are empty |
| top-anchored-006 | flipped-origin | Add a subview with frame origin (0, 10) and read its frame's minY in the view's coordinates | 10 points below the top edge |
