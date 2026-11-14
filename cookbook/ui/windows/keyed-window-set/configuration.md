
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `setting` | `UserSetting<[String]>` | none | Where the ordered key list persists; the owner names it. |
| `open` | `(key, activates, onClose) -> Controller?` | none | Makes the key's window, or returns `nil` when it cannot. |
| `bringForward` | `(Controller) -> Void` | none | Shows the window already open for a key. |

