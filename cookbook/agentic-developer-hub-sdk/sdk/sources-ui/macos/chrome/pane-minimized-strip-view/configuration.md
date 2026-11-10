
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `edge` | `PaneEdge` enum | required | Which side the pane docks to (`.leading` or `.trailing`); determines hairline placement. Set once at initialization — there is no stored property or setter to change it afterward. |
| `symbolName` | `String` | `"square.dashed"` | SF Symbol name to display as the glyph |
| `tooltip` | `String` | `""` (empty) | Tooltip text for the glyph; no tooltip if empty |
| `onRestore` | `() -> Void` closure | `nil` | Callback invoked when restore button is tapped |

