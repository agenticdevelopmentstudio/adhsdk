
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (Wrapper) | boolean | Required | Controlled checked state. MUST be provided. |
| `onChange` (Wrapper) | (value: boolean) => void | Required | Callback invoked when user toggles the checkbox. MUST be provided. |
| `appearance` (Wrapper) | 'switch' \| 'check' | 'switch' | Visual and semantic mode: switch toggles with switch role, check renders as checkbox. |
| `disabled` (Wrapper) | boolean | false | When true, prevents user interaction via the native `disabled` attribute on the input. |
| `label` (Wrapper) | ReactNode | undefined | Optional label text rendered adjacent to checkbox with associated `htmlFor`. |
| `hint` (Wrapper) | ReactNode | undefined | Optional hint text rendered below checkbox in a paragraph element. |
| `className` (Wrapper) | string | undefined | Custom CSS class(es) appended to the wrapper's root container. |
| `id` (Wrapper) | string | `useId()`-generated id | HTML id attribute for the input element, used for label association. Auto-generated if not provided. |
| `checked` (Primitive) | boolean | undefined | Primitive's controlled checked state, paired with `onCheckedChange`. Not used together with `defaultChecked`. |
| `defaultChecked` (Primitive) | boolean | false | Primitive's initial checked state for uncontrolled usage; replaces `checked`/`onCheckedChange`. |
| `onCheckedChange` (Primitive) | (checked: boolean) => void | undefined | Primitive's change callback in controlled mode, paired with `checked`; forwarded to Base UI's `CheckboxPrimitive.Root`. |
| `disabled` (Primitive) | boolean | false | When true, Base UI blocks toggling and the Primitive renders the box at 50% opacity with pointer events off (see **disabled-state**). |
| `className` (Primitive) | string | undefined | Custom CSS class(es) merged into `CheckboxPrimitive.Root`'s class list via `cn()`. |
