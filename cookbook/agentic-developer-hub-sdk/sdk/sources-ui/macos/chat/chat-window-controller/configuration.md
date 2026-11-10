
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `String` | Required | Window title, hidden in title bar but used by Window menu and accessibility |
| `defaultsNamespace` | `String` | Required | Prefix for saved appearance settings; namespaces allow multiple windows to maintain independent settings |
| `appearanceTitle` | `String` | Required | Caption for the appearance control panel, localized to the reader's language |
| `contentSize` | `NSSize` | `(460, 620)` | Initial width and height of the window's content area |
| `chrome` | `InlineChatChrome` | Default instance | Chat view styling (stock look or terminal theme) |
| `backdropToggleTitle` | `String` | `"Background animation"` | Label for the backdrop animation toggle in the appearance panel; e.g., `"Rain"` for a window with rain backdrop |

