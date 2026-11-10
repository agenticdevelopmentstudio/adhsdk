
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `parentWindow` | NSWindow | (required) | The window the drawer is attached to. |
| `accessibilityPrefix` | String | (required) | Namespace for accessibility IDs; e.g., "help" produces IDs like "help.tabs" and "help.tab.settings". |
| `tabs` | [DrawerTab] | (required) | Array of tab definitions; each has `id`, `title`, `symbolName`, and lazy view factory. Fixed at initialization; there is no API to add or remove tabs afterward. |
| `contentWidth` | CGFloat | 300 | Initial width in points; clamped to 220–520 on init and on setter. |
| `onVisibilityChange` | `(() -> Void)?` | `nil` | Callback invoked after every open, close, or drag-initiated visibility change. |
| `reapplyVisibility` | `(() -> Void)?` | `nil` | Callback invoked when the parent window becomes key or main; lets the caller re-open a remembered drawer that was dropped during `init`. |

