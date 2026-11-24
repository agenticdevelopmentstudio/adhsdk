
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | PaneStateStore | none (required) | The pane's key and string store the provider reads and writes |
| prefix | String | `settings.` | Where the pane's settings live among its state keys; also prefixes the index key |
| defaultPrefix | static String | `settings.` | The default prefix constant |
| indexName | static String | `__keys` | The key, after the prefix, of the list of names a pane overrides |

