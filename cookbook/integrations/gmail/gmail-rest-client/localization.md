
The client emits two hardcoded English strings and one system-localised string; server text passes through untranslated.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `Invalid URL for <path>` | `IntegrationError.gmail` message when the URL cannot be built. |
| none (hardcoded) | `batchModify takes 1–1000 ids, got <count>` | `IntegrationError.gmail` message from the bounds guard; the dash is an en dash. |
| `HTTPURLResponse.localizedString(forStatusCode:)` | system text for the status | Message used when an error body has no `error.message`; localised by the operating system. |

Gmail's own `error.message` is shown as received, in whatever language Google returns. Turning `IntegrationError` into display text happens in `IntegrationError.errorDescription`, outside this client.

