
| State | Appearance change |
|-------|------------------|
| Default (no `onSelect`) | Plain text rows with bars; no row is interactive |
| Selectable | Each row is a button; cursor is a pointer; no row dimmed while `selected` is null |
| Selected | The row whose name equals `selected` is pressed and full opacity; all other rows are at 55% opacity |
| Hover | Not applicable for rows: the source defines no hover style on a row button. The expand button's text moves from muted to full text color |
| Focused (keyboard) | 2px gold ring at 40% opacity around the row button or the expand button |
| Pressed (active) | Not applicable: the source defines no `:active` style for any element |
| Disabled | Not applicable: neither a row button nor the expand button has a disabled state in source |
| Loading | Not applicable: the component receives all data as props and has no loading state |
| Collapsed overflow | The first `maxItems` rows; expand button reads "Show all N" and reports not expanded |
| Expanded overflow | All rows; expand button reads "Show fewer" and reports expanded |
| Empty | Only the `emptyLabel` text; no list and no button |

