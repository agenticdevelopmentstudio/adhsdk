
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| commit-graph-cell-001 | width | row with `width` 3 | `intrinsicContentSize.width` 42; no row: 0. |
| commit-graph-cell-002 | lane-colour | lanes 0, 5, 6, 11, 12 | ANSI slots 1, 6, 9, 14, 1. |
| commit-graph-cell-003 | lane-colour | a theme with no ANSI slots | every lane is the `accent` colour. |
| commit-graph-cell-004 | node | one-parent row vs two-parent row at column 0, drawn 14 × 20 | the centre pixel is painted for the commit and transparent for the merge. |

