
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `heading` | `String?` | (required) | The optional heading text displayed at the top of the dialog; the initializer declares no default, so callers must pass `nil` explicitly to start with no heading. Settable after initialization; `nil` hides the heading. |
| `rows` | `[NSView]` | (required) | An array of NSView subclasses to render as dialog rows. Passed at initialization only. |
| `width` | `CGFloat` | `340` | The minimum (floor) width of the dialog in points. Dialog expands if row content requires more space. |
| `accessibilityPrefix` | `String` | `"options"` | Prefix for accessibility identifiers applied to the dialog and Done button. Allows multiple dialogs to coexist without ID collisions. |

