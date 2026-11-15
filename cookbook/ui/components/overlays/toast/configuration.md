
`ToastProvider` is Base UI's provider, re-exported unchanged, and accepts two options that matter here, and `Toaster` takes one prop, `closeLabel`. The viewport position and toast dimensions are fixed.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `limit` | number | 3 | Maximum number of simultaneously visible toasts; older toasts beyond it are marked `data-limited`. This ingredient recommends passing it explicitly (see **set-explicit-limit**). |
| `timeout` | number (ms) | 5000 | How long a toast stays before closing itself (see **auto-dismiss-timeout**). |
| `closeLabel` (`Toaster`) | string | `"Close"` | The close button's `aria-label`; pass the localized string (see **localize-close-label**). |

Consumers supply content with `useToast().add({ title, description })`.
