
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mode` | "auto" \| "dark" \| "light" | (required) | The current color mode preference. Parent must provide this; not stored in component state. |
| `onChange` | (next: ColorMode) => void | (required) | Callback invoked when user clicks button. Receives the next mode in the cycle. |
| `className` | string | undefined | Optional CSS class name to apply to the button element. Used to integrate the button's styling with the host application's button identity. |

