
| Option | Type | Default | Description |
|---|---|---|---|
| `children` | `React.ReactNode` | — | The chip label/content shown in the badge body. |
| `onRemove` | `() => void` | — | Called when the ✕ button is activated. Required. |
| `removeLabel` | `string` | — | Accessible name for the ✕ button (e.g. `Remove ${value}`). Required. |
| `variant` | `"neutral" \| "accent" \| "orange" \| "blue" \| "success" \| "error"` | `"neutral"` | Badge tone. |
| `disabled` | `boolean` | `false` | Disables the ✕ button. |
| `className` | `string` | — | Extra classes for the badge body; merged via `cn()`. |
| `...props` | `Omit<React.ComponentProps<"span">, "children">` | — | Native span props forwarded onto the `Badge`. |

