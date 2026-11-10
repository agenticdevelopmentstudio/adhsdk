
| State | Appearance change |
|---|---|
| Default row | `text-apt-text`, transparent background |
| Hover row | `bg-apt-surface-2` |
| Selected row | `bg-apt-gold/15`, `aria-selected="true"`, `data-selected` |
| Keyboard-focused row | roving `data-focused="true"`; `aria-activedescendant` points at it |
| Dragging row | row's transform reflects pointer position (dnd-kit) |
| Sortable header (active) | `aria-sort` set to "ascending" or "descending"; caret reflects direction |
| Loading | loading affordance shown in place of rows (status message) |
| Empty | `emptyLabel` (default "No items.") shown |

