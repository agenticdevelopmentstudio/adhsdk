
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | `ReactNode` | `undefined` | Optional label text or element rendered above the select |
| `hint` | `ReactNode` | `undefined` | Optional hint text or element rendered below the select |
| `value` | `T` (extends `string`, default `string`) | Required | The currently selected value (controlled component) |
| `onChange` | `(value: T) => void` | Required | Callback invoked when the user changes the selection |
| `choices` | `Choice<T>[]` | Required | Array of options; each choice has `value`, `label`, and optional `disabled` |
| `disabled` | `boolean` | `false` | Disables the select element and prevents user interaction |
| `className` | `string` | `undefined` | Optional CSS class name; applied to the wrapper div in the `aws-field` implementation, and to the `<select>` element itself in the apt-token implementation |
| `id` | `string` | Generated via `useId()` | Optional HTML id; if not provided, one is automatically generated |

