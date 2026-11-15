
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `browser.back` binding | key command binding | Command-[ | Back's shortcut, rebindable in Keyboard Shortcuts › Web Browser. |
| `browser.forward` binding | key command binding | Command-] | Forward's shortcut, rebindable in Keyboard Shortcuts › Web Browser. |
| `browser.privacy.show_toolbar` | bool, per pane over global | off | Read for the toggle's title; written as a per-pane override by the toggle. |
| key pane provider | injected closure | key window's browser pane | Supplies the target pane; injected so tests can supply a stub. |
| show history action | injected closure | opens the History window | What Show History does. |

