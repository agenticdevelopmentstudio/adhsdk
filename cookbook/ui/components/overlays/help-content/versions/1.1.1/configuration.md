
### HelpContentProvider props

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| help | `Record<string, HelpEntry>` | — | A dictionary of help entries keyed by component id. Required for HelpContentProvider. |

### HelpEntry fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| title | string | undefined | Optional heading for a help entry. Omitted for entries with no title. |
| body | string | — | The help text content. Required for every HelpEntry. |
| flavor | "help" \| "info" \| "new" | "info" | Flavor tag categorizing the type of help content. See **default-flavor-to-info** for where the default is applied. |

