
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `[IconTabBar.Item]` | none, required at init | One segment each; an item is an `id`, a `symbol` name and a `title` |
| `accessibilityID` | `String` | none, required at init | The control's accessibility identifier |
| `selectedID` | `String?` | `nil` | The item drawn as chosen; `nil` for none |
| `onSelect` | `((String) -> Void)?` | `nil` | Called with the clicked item's `id` |

