
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `eventType` | `String` | required | Hook event name |
| `timestamp` | `String` | required | Event timestamp text |
| `hookData` | `[String: Any]` | required | Hook payload |
| `context` | `[String: Any]?` | required (may be nil) | Facts about the live `claude` process, resolved at capture |
| `accountEmail` | `String` | required | Fingerprinted account email, empty when none |
| `oauthAccountEmail` | `String?` | `nil` | Oauth login at capture; nil means the envelope predates the field |

