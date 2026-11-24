
| Option | Type | Default | Applies To | Description |
|--------|------|---------|------------|-------------|
| `label` | `ReactNode` | `undefined` | Both | Optional label text or node displayed above the input. |
| `hint` | `ReactNode` | `undefined` | Both | Optional helper text or node displayed below the input in a `<p>` element; passing block-level content produces invalid HTML, so keep it to inline content. |
| `value` | `string` | (required) | Both | Current text value; controlled by caller. |
| `onChange` | `(value: string) => void` | (required) | Both | Callback invoked when input value changes. |
| `placeholder` | `string` | `undefined` | Both | Placeholder text shown when input is empty. |
| `multiline` | `boolean` | `false` | TextField (typed on `SecureTextFieldProps` too, but `SecureTextField`'s implementation never reads it and always renders a single-line masked `<input>`) | When `true`, renders a `<textarea>` instead of `<input>`. |
| `disabled` | `boolean` | `false` | Both | When `true`, input is disabled and user cannot interact with it. |
| `className` | `string` | `undefined` | Both | Optional CSS class name(s) to append to root element. |
| `id` | `string` | (auto-generated) | Both | Optional ID for the input element; generated via `useId()` if omitted. |
| `type` | `'text' \| 'email' \| 'url' \| 'tel'` | `'text'` | TextField only | Input type for single-line TextField. |
| `autoComplete` | `string` | `undefined` | TextField only | Autofill token (e.g., `'email'`, `'tel'`) to enable password manager integration; omit or use `'off'` to prevent autofill. `SecureTextField` accepts no equivalent prop — see **always-prevent-password-manager**. |

