
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `window` | window-lookup function | none (required; construction takes no default) | Queried fresh on every presentation call to decide which window an alert attaches to; an absent result falls back to selecting any visible window before the message is dropped. |
| `request` | message request | none (required, supplied per presentation call) | The per-call payload — severity, message, detail, modal flag, item titles, close-affordance indices; its own field shapes, defaults, and invariants are documented in Extension Message Presenting ([adhsdk.ingredient.workspace.extensions.vscode-api.window.extension-message-presenting](cookbook:0aa82a1f-42ed-4585-9f65-bb20aa110712)) rather than restated here. |

