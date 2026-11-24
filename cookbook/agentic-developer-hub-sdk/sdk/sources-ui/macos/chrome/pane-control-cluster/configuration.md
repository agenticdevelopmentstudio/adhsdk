
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `isZoomed` | `Bool` | `false` | Flips the zoom glyph and tooltip. Set by the host; the component never infers it from a click. |
| `isMinimized` | `Bool` | `false` | Turns the minimize button into restore — glyph, tooltip, action, and accessibility identifier. |
| `canMinimize` | `Bool` | `true` | False for a pane with no sibling to hand its space to. Ignored while minimized, so restoring stays reachable. |
| `canClose` | `Bool` | `true` | False for a pane its container will not give up. |
| `onClose` | `(() -> Void)?` | `nil` | Invoked when the close button is activated. |
| `onMinimize` | `((NSButton) -> Void)?` | `nil` | Invoked, with the minimize button as an anchor, when it is activated in the non-minimized state. |
| `onRestore` | `(() -> Void)?` | `nil` | Invoked when the minimize button is activated in the minimized state. |
| `onZoom` | `(() -> Void)?` | `nil` | Invoked when the zoom button is activated. |

