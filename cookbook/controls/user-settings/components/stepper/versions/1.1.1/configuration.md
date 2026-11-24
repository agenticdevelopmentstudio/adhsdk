
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | number | required | Current numeric value |
| `onChange` | (value: number) => void | required | Callback invoked when value changes |
| `min` | number | -Infinity | Minimum allowed value |
| `max` | number | +Infinity | Maximum allowed value |
| `step` | number | 1 | Increment/decrement step size |
| `disabled` | boolean | false | Disables all controls |
| `label` | ReactNode | undefined | Optional label text or element |
| `hint` | ReactNode | undefined | Optional hint or help text |
| `className` | string | undefined | Optional custom CSS class |
| `id` | string | auto-generated | Optional custom element ID |

