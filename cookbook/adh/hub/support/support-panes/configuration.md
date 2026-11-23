
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Which routes `SupportAccessPane` calls. |
| `ecosystemId` | string | none, required | The product `SupportGrantsPane` asks for grants in. |
| `returnPath` | string | `/support` | Where `SupportGrantsPane`'s step-up sign-in comes back to. |
| `onStepUp` | function | the product admin session's `stepUp` | Overrides the step-up of `SupportGrantsPane`. |
| `help` | node | none | Help content for each operator pane's title. |
| Length | hours | 24 (1 for break-glass) | Default request length; whole hours, bounds 1 to 168 (consented), 1 to 4 (break-glass). |
| Reason | characters | none | 10 to 500. |
| Attestation | characters | none | At least 40, counted trimmed. |
| Reference | characters | none | Required for break-glass; at most 500. |

