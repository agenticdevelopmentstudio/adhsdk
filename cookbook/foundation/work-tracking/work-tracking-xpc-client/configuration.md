
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `transport` | `WorkTrackingXPCTransport` | required | Answers `callData` and `callDecodingArray`. |
| `recheckTimeout` | `TimeInterval` | 15 | Wait for a recheck. |
| `setPreferencesTimeout` | `TimeInterval` | 15 (equals `recheckTimeout`) | Wait for a preferences push. |
| status and spans timeout | `TimeInterval??` | nil | Passed through to the transport. |
| retries | `Int` | 0 | Passed on every call. |

No environment variables or settings keys.

