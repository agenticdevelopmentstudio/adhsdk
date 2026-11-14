
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `accounts` (initializer argument) | `[any Account]` | `[]` | The initial accounts, in display order. |
| `onChange` | `@MainActor () -> Void` | empty closure | Observer assigned after construction; fires after a successful `add` or `remove`. |

The registry reads no environment variables or settings keys. Each `Account` is injected by the caller.

