
| State | Appearance change |
|-------|------------------|
| Closed (`open: false`) | Component not rendered; does not appear in DOM. |
| Open (empty query) | Input field focused, results section not shown. |
| Open (with query, results found) | Results grouped by section are visible; selected result highlighted. |
| Open (with query, no results) | "No results for "{query}"" message displayed. |
| Result selected (default or via keyboard) | Result button receives `awt-search-dialog__result--selected` class. `selectedIndex` starts at, and every query change resets it to, `0`, so the top-ranked result is pre-selected as soon as results exist — arrow keys move the selection from there. |
| Result hovered | Controlled by CSS; source does not specify hover behavior. |

