
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | (required) | Controls whether the dialog is rendered and visible. |
| `onClose` | `() => void` | (required) | Callback invoked when user dismisses the dialog (Escape key or backdrop click). |
| `state` | `SearchState` | (required) | Mutable state object managing query, results, and selection. Must implement `reset()`, `setQuery(q)`, `handleKey(e)` methods. |
| `onSelect` | `(entry: SiteEntry) => void` | (required) | Callback invoked when user selects a result. |
| `sectionLabels` | `Record<string, string>` | `{}` | Optional mapping of section keys to display labels. Untranslated section keys appear as-is. |
| `placeholder` | `string` | `"Search documentation..."` | Placeholder text shown in the input field. |

