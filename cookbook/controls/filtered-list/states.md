
| State | Appearance change | Trigger |
|-------|------------------|---------|
| Default | No item highlighted, input shows query text | Initial state |
| Highlighted | Item has fl-item--active class, input shows item title, aria-selected="true" | Arrow keys, mouse hover |
| Filtered | List shows only matching items, empty state shown if no matches | User types in input |
| Disabled/Empty | "No items." message shown, list not rendered | total === 0 |
| Focused | Input has keyboard focus | User clicks input or autoFocus=true |

