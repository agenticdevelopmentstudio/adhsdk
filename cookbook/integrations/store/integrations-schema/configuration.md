
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | `BoundedDatabase` | none (required) | The database to migrate; `migrate` uses its `writer` property. Supplied by the caller, in practice `IntegrationsStore.init(database:)`. |

