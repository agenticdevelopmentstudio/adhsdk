
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | ReactNode | undefined | Custom headline text; overrides computed headline and `selectable` |
| `noun` | string | undefined | Singular noun for the selectable item (e.g. "workspace", "site") |
| `listTitle` | string | undefined | Display name of the list; used as fallback when noun not provided |
| `selectable` | boolean | true | Whether the list has items to select; false hides the computed headline (not an explicit `title`) and shows only children |
| `children` | ReactNode | undefined | Optional descriptive content (e.g. "What these items are and why to pick one") |

