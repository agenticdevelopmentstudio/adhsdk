
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Which routes `SupportAccessPane` calls. |
| `ecosystemId` | string | none, required | The product `SupportGrantsPane` asks for grants in. |
| Length | hours | 24 | Default request length; bounds 1 to 168 (consented), 1 to 4 (break-glass). |
| Reason | characters | none | 10 to 500. |
| Attestation | characters | none | At least 40. |

