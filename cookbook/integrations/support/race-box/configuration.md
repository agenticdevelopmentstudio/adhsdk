
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `T` | `Sendable` generic parameter | none, required | The success value the box carries. |
| `init()` | no parameters | fixed | Creates an unsettled box with no waiters. |
| `finish(_:)` argument | `Result<T, Error>` | none, required | The outcome a task offers. |

There are no environment variables, settings keys, timeouts or injected dependencies. The deadline and cancellation hooks belong to the callers.

