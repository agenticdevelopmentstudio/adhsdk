
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `String` | (required) | The dialog window's title, displayed in the title bar. Settable at runtime. |
| `tooltip` | `String` | `"Window appearance"` | Tooltip for the gear button, set on construction. |
| `width` | `CGFloat` | component's built-in default (see Platform Notes) | Width of the dialog's body, allowing hosts with wider controls to avoid cramping. |
| `makeControls` | `@MainActor () -> [NSView]` | (required) | Closure that returns an array of row views (sliders, toggles, etc.) to display in the dialog. Called at open time so controls read live state. |
| `gearButton` | `NSButton` (read-only public) | Auto-created | The button to be placed in the window's chrome, created and configured by the component. |
| `isShown` | `Bool` (read-only) | `false` initially | Whether the dialog is currently visible. |

