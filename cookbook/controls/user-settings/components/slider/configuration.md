
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | `ReactNode` | `undefined` | Optional label text or element displayed above the input |
| `hint` | `ReactNode` | `undefined` | Optional hint text or element displayed below the slider |
| `value` | `number` | (required) | Current value of the slider; controlled by the parent component |
| `onChange` | `(value: number) => void` | (required) | Callback invoked when the user changes the slider value |
| `min` | `number` | `0` | Minimum value of the slider range |
| `max` | `number` | `100` | Maximum value of the slider range |
| `step` | `number` | `1` | Increment/decrement step when user adjusts the slider |
| `caption` | `ReactNode \| (value: number) => ReactNode` | `undefined` | Optional static content or function that returns dynamic content based on the current value |
| `disabled` | `boolean` | `false` | When `true`, disables the input and prevents user interaction |
| `className` | `string` | `undefined` | Optional additional CSS class name(s) to apply to the wrapper element |
| `id` | `string` | (auto-generated) | Optional ID for the input element; if not provided, a unique ID is generated using React's `useId` |

