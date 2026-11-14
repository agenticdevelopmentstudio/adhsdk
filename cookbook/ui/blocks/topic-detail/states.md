
| State | Appearance change |
|---|---|
| Default | Row in `text-apt-text`, transparent left border |
| Pressed | Not applicable: rows are plain buttons with no pressed styling in source |
| Disabled | Row dimmed to `text-apt-text-dim`, default cursor, no hover bar, checkbox disabled |
| Focused | Native focus on the row; arms prefetch; the trash button and tools show `focus-visible` rings |
| Loading | `busy` shows a spinning loader after the title and "Loading" in the status region |
| Active row | Gold text, left bar (bar style) or full-height gold bar flush left (marker, root, not collapsed), `aria-current="true"` |
| Hover | Text-coloured left bar when `hoverBar` is true; trash button fades in |
| Blocked | Amber dot on the icon, `data-blocked="true"`, "needs attention" in the name |
| Link flash | The chosen link row appears active for 1000ms |
| Collapsed | 48px strip, icon-only rows with tooltips, no toolbar |
| Covered | Left-aligned icon-only strip, no tooltip, re-click is a no-op |
| Dragging | Width transition off, rail tracks the pointer |
| Delete pending | Confirmation dialog open; busy while the delete runs |
| Delete failed | Dialog stays open, busy cleared |
| Filter open | Panel over the toolbar; suggestions, "Searching…" or "Nothing matches" below; rows invisible under them |
| Filter active, closed | Filter button gold |
| Batch | Checkbox in each expanded row |
| Below `md` | One column, rail above pane, toggle and drag handle hidden |

