
| Option | Type | Default | Description |
|---|---|---|---|
| `variant` | `"default" \| "outline" \| "secondary" \| "ghost" \| "destructive" \| "warning" \| "destructive-ghost" \| "link"` | `"default"` | Visual style. |
| `size` | `"xs" \| "sm" \| "default" \| "lg" \| "icon" \| "icon-xs" \| "icon-sm" \| "icon-lg"` | `"default"` | Size/shape. |
| `className` | `string` | — | Extra classes merged via `cn()`. |
| `disabled` | `boolean` | `false` | Disables the button. |
| `...props` | `Base UI Button.Props` | — | All native button props (incl. `onClick`, pointer handlers, `aria-*`, `render`) are forwarded. |

`buttonVariants({ variant, size, className })` is also exported for styling a
non-button trigger (e.g. a `<Link>`); it stays server-callable.

