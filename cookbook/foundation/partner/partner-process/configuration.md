
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` | `PartnerProcessConfiguration` | none, required | Supplies the executable, arguments and working directory (see Partner Process Configuration ([adhsdk.ingredient.foundation.partner.partner-process-configuration](cookbook:c77c4cfb-e9be-4339-b40d-3f7abc6a4543))). |
| `environment` | `[String: String]` | none, required | The child's whole environment under the replace policy; an empty dictionary inherits the parent's. |
| framing | fixed | newline-delimited | One JSON object per line in both directions. |
| stream buffer | fixed | unbounded | The default `AsyncStream` buffering policy. |

