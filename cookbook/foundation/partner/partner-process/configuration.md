
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` | `PartnerProcessConfiguration` | none, required | Supplies the executable, arguments and working directory (see the Partner Process Configuration recipe). |
| `environment` | `[String: String]` | none, required | The child's whole environment under the replace policy; an empty dictionary inherits the parent's. |
| framing | fixed | newline-delimited | One JSON object per line in both directions. |
| stream buffer | fixed | unbounded | The default `AsyncStream` buffering policy. |

