
| Option | Type | Default | Description |
|---|---|---|---|
| `column` | `CrudColumn` (`name`, `type`, `required`, `nullable`, `serverManaged`, ...) | required | Descriptor of the column the value belongs to; only `name` and `type` are read |
| `value` | `unknown` | required | The raw row value for that column |
| `UNIX_SECONDS_COLUMNS` | `Set<string>` | `created`, `updated` | Module-private set of column names whose integer values are unix seconds; not caller-configurable |
| `unixToIso` | function from `@adh-sdk/auth/client` | imported | The seconds-to-ISO converter; returns null for a null, undefined or non-finite input, otherwise the UTC ISO string |

