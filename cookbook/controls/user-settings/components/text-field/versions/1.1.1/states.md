
| State | Appearance change |
|-------|------------------|
| Default | Input or textarea rendered normally with base styling applied via `.aws-field__input` or `.aws-field__textarea`. |
| Disabled | `disabled` attribute applied to input/textarea; `.aws-field__input:disabled` drops opacity to `0.55`. |
| Focused | `.aws-field__input:focus` sets `border-color: var(--aws-accent)`; component does not apply inline focus styles. |
| Placeholder visible | When `placeholder` prop is provided and input is empty, browser renders the placeholder text. |
| With label | When `label` prop is provided, a `<label>` element is rendered above the input. |
| With hint | When `hint` prop is provided, hint text is rendered below the input in a `<p>` element. |
| Multiline | Textarea element with `rows={4}` rendered instead of input element when `multiline` is `true`. |
| SecureTextField | Additional `'aws-field--secure'` class applied; input type is always `'password'`; autofill always prevented. |

