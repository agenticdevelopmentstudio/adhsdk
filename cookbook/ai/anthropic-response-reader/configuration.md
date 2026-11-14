
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `streaming` | boolean (init argument) | none (required) | Selects server-sent-event parsing (`true`) or whole-JSON parsing (`false`). |
| `jsonLimit` | integer, internal constant | 4194304 (4 MiB) | Largest non-streaming body buffered, and the cap on an unterminated streaming line. Not caller-settable. |

