
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` (every-row read state) | `boolean`, per call | `true` | Gates the authed request; pass the signed-in state |
| `enabled` (preference read state) | `boolean`, per call | `true` | Gates the read; `false` reports `slug: null` |
| preference cache key | exported constant | `'workspace-prefs'` | The shared item-cache key every reader and writer of the preference row uses |
| preference item id | exported constant | `'me'` | The row's id in that cache; the item cache's tenant scoping already separates one signed-in caller from the next |
| preference loader | exported function | Resource Data's workspace-preferences read | Module-scope, so the item read state can hold it in a dependency list |
| query client | injected by the toolkit | the toolkit's own query client | The every-row read state always uses the toolkit client, never a host's |

