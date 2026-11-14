
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `code` | `string` | required | Trusted, static JavaScript source placed unescaped inside the `script` element |

Fixed behavior: the server snapshot is `true`, the client snapshot is `false`, and the subscription is a no-op. There are no environment variables, settings keys or injected dependencies.

