
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `kind` | `BrowserJarRecord.Kind` | none (required) | `worktree` or `pane` |
| `label` | `String` | empty | Last name the jar was shown under |
| `id` | `UUID` | new random UUID | The WebKit store identifier |
| `statePrefix` | `String` | the composable-tabs registry's browser state prefix | Where an engine files its pane state |
| `ownerNodeID` | `UUID?` | `nil` | Layout node a nested pane files its rows under |

The storage-jar setting name, its `global` value and the settings-key shape
come from `BrowserStorageJar` and `PaneStateSettingsStorageProvider`, injected
by the surrounding module.

