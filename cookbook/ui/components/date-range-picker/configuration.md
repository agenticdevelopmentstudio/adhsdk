
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | `DateRange` | required | The current range, `from` and `to` as `YYYY-MM-DD`. |
| `onChange` | `(range: DateRange) => void` | required | Called with the new range when a field changes to a non-empty date. |
| `min` | `string` | none | Earliest selectable day, `YYYY-MM-DD`; bounds the From field only. |
| `max` | `string` | none | Latest selectable day, `YYYY-MM-DD`; bounds the To field only. |
| `className` | `string` | none | Extra classes merged onto the wrapper. |

