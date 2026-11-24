
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `checked` | boolean | undefined | Controlled state; when present, component is controlled mode |
| `onCheckedChange` | function | undefined | Callback fired when user toggles state; signature: `(checked: boolean) => void` |
| `defaultChecked` | boolean | undefined | Initial state for uncontrolled mode |
| `disabled` | boolean | false | Blocks toggling via Base UI's internal guards; the intended dimmed styling (`disabled:opacity-50` etc.) never applies because the root is a `<span>`, not a native-disabled element — see **Disabled communication** |
| `className` | string | "" | Additional CSS class names merged with component's internal styles |
| `name` | string | — | Form field name; forwarded via `{...props}` to base-ui's `Switch.Root` for native form submission |
| `value` | string | — | Form value submitted when checked; forwarded via `{...props}` to `Switch.Root` |
| `required` | boolean | — | Marks the field required for form validation; forwarded via `{...props}` to `Switch.Root` |
| `readOnly` | boolean | — | Blocks user-driven changes while still reflecting controlled prop updates; forwarded via `{...props}` to `Switch.Root` |
| `inputRef` | Ref | — | Ref to the underlying native input element; forwarded via `{...props}` to `Switch.Root` |

The last five props aren't handled by this wrapper directly — they pass through the `{...props}` spread to base-ui's `Switch.Root`, whose contract defines their exact defaults and behavior.

