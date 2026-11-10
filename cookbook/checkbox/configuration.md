
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (Wrapper) | boolean | Required | Controlled checked state. MUST be provided. |
| `onChange` (Wrapper) | (value: boolean) => void | Required | Callback invoked when user toggles the checkbox. MUST be provided. |
| `appearance` (Wrapper) | 'switch' \| 'check' | 'switch' | Visual and semantic mode: switch toggles with switch role, check renders as checkbox. |
| `disabled` (Wrapper) | boolean | false | When true, prevents user interaction via the native `disabled` attribute on the input. The same value forwarded to the Primitive produces no visual dimming — see **disabled-state**. |
| `label` (Wrapper) | ReactNode | undefined | Optional label text rendered adjacent to checkbox with associated `htmlFor`. |
| `hint` (Wrapper) | ReactNode | undefined | Optional hint text rendered below checkbox in a paragraph element. |
| `className` (Wrapper) | string | undefined | Custom CSS class(es) appended to the wrapper's root container. |
| `id` (Wrapper) | string | `useId()`-generated id | HTML id attribute for the input element, used for label association. Auto-generated if not provided. |
| `checked` (Primitive) | boolean | undefined | Primitive's controlled checked state, paired with `onCheckedChange`. Not used together with `defaultChecked`. |
| `defaultChecked` (Primitive) | boolean | false | Primitive's initial checked state for uncontrolled usage; replaces `checked`/`onCheckedChange`. |

