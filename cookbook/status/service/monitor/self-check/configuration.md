
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `checks` | `readonly IntegrationCheck[]` | none, required | The stabilised integration checks to judge. |
| Excluded id | string literal `"cron"` | `"cron"` | The one check id never chipped as an issue; hardcoded, not configurable. |

The function reads no environment variable and takes no other parameter.

