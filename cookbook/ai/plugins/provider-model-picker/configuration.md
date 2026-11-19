
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Provider source | provider source | — (required) | Local or daemon. |
| Provider selection | text setting | — (required) | The selected provider id, or a leading choice's id. |
| Model setting | function from provider id (none for a leading choice) to optional text setting | — (required) | The model setting for a provider; `""` means the provider's default. |
| Leading choices | list of (id, title) | empty | Sentinel entries listed first. |
| Provider label | text | "Provider" | The provider row's label. |
| Model label | text | "AI Model" | The model row's label. |

The provider source is built before the control and takes its own
parameters: the daemon source takes the daemon client and an optional plugin
manager (default none), which resolves templates for display names and the
chooser's list; the local source takes the plugin manager.
