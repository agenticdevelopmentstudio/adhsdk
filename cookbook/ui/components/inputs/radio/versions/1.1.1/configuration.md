
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (RadioGroup) | string | — | The controlled selected value for the group; the RadioGroupItem whose own `value` matches renders as checked |
| `defaultValue` (RadioGroup) | string | `undefined` | Initial selected value for an uncontrolled group |
| `onValueChange` (RadioGroup) | `(value: string) => void` | `undefined` | Callback invoked with the new value when the user selects a different item |
| `name` (RadioGroup) | string | auto-generated | Shared form field name applied to all items in the group |
| `disabled` (RadioGroup) | boolean | `false` | Disables every RadioGroupItem in the group |
| `value` (RadioGroupItem) | string | required | The value this item represents; compared against the group's `value` to determine checked state |
| `disabled` (RadioGroupItem) | boolean | `false` | Disables this individual item, overriding group-level enablement |
| `className` | string | `undefined` | Additional CSS classes applied to RadioGroup or RadioGroupItem |

