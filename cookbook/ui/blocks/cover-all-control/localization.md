
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `cover_all.group_label` | "Collapse or expand all lists" | Group name of the frame |
| `cover_all.collapse` | "Collapse all lists" | Collapse button name and tooltip |
| `cover_all.expand` | "Expand all lists" | Expand button name and tooltip |

All three strings are hardcoded English with no override prop. The chevrons point left to collapse and right to expand in every layout direction: the source uses `ChevronLeft` and `ChevronRight` directly, `rounded-l` on the left half and `rounded-r` on the right half, and no logical-direction classes, so a right-to-left layout would not mirror them.

