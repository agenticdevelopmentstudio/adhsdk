
`SiteHelp` is the type `Record<string, HelpEntry>`: a help dictionary keyed by component id.

### HelpContentProvider props

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| help | `SiteHelp` | — | A dictionary of help entries keyed by component id. Required for HelpContentProvider. |

### HelpEntry fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| title | string | undefined | Optional heading for a help entry. Omitted for entries with no title. |
| body | string | — | The help text content. Required for every HelpEntry. |
| flavor | "help" \| "info" \| "new" | — | Flavor tag categorizing the type of help content. Absent ⇒ the consumer treats it as `info`; the hook supplies no value. See `#requirements/default-flavor-to-info`. |

