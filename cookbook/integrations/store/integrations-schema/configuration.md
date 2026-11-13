
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | `BoundedDatabase` | none (required) | The database to migrate; `migrate` uses its `writer` property. Supplied by the caller, in practice `IntegrationsStore.init(database:)`. |
| Migration name | `String` | `integrations-v1` | Fixed identifier GRDB records once the migration has run. Not configurable. |
| Database path | `String` | none | Owned by the caller's `BoundedDatabase` (a file path or `:memory:`); the schema never opens a file. |

