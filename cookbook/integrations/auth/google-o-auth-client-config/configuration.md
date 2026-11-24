
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clientId` | `String` | none (required) | The Google OAuth client ID, passed to the initializer or read from `installed.client_id` |
| `clientSecret` | `String` | none (required) | The Google OAuth client secret, passed to the initializer or read from `installed.client_secret` |
| `json` | `Data` | none (required) | The downloaded client file given to `parse(json:)` |

The type reads no environment variables, settings keys or files and has no injected dependencies. The accepted file shape is the object keyed `installed` with string members `client_id` and `client_secret`.

