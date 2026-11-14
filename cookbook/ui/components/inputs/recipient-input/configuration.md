
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | `string[]` | — (required) | Controlled array of recipient strings. The component does not modify this directly; changes flow through `onChange`. |
| `onChange` | `(next: string[]) => void` | — (required) | Called with the updated recipient array on any add or remove. Not called when no chip is added (a rejected duplicate or an all-whitespace commit) and not called in `readOnly` mode. |
| `kind` | `"email" \| "phone" \| "text"` | `"text"` | Validation mode and input type hints. `"email"` and `"phone"` apply regex validation; `"text"` skips validation. |
| `placeholder` | `string` | `"Add email…"`, `"Add phone…"`, or `"Add…"` (depends on `kind`) | Placeholder text for the inline input. If not provided, a default matching `kind` is used. In separate mode, placeholder is applied to the separate Input. In fused mode, placeholder is shown only when chips list is empty. |
| `ariaLabel` | `string` | — (required) | Accessible label for the container group. Input field label is derived as `Add to ${ariaLabel}`. |
| `disabled` | `boolean` | `false` | When true, the component is dimmed and pointer-inert, and the input is disabled so nothing can be typed. Chip remove buttons are not natively disabled, so a keyboard user can still remove a chip (see Edge Cases). |
| `className` | `string` | — | Additional CSS classes applied to the root container. |
| `separateInput` | `boolean` | `false` | When true, renders the recipients box and input as two visually distinct stacked elements instead of one fused container. Chips in the recipients box remain removable unless `readOnly` is also set. |
| `readOnly` | `boolean` | `false` | When true, recipients display as static, non-removable Badge chips and no input field is rendered. Useful for displaying fixed recipient lists from the server. `onChange` is never called in this mode. |

