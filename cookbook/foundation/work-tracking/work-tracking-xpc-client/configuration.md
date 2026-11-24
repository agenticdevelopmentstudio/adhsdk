
| Option | Type | Value | Description |
|--------|------|-------|-------------|
| `transport` | `WorkTrackingXPCTransport` | required, injected through `init` | Answers `callData` and `callDecodingArray`. |
| `recheckTimeout` | `TimeInterval` | constant 15 (static, not injectable) | Wait for a recheck. |
| `setPreferencesTimeout` | `TimeInterval` | constant, equal to `recheckTimeout` (static, not injectable) | Wait for a preferences push. |
| status and spans timeout | `TimeInterval??` | constant `.none` | Passed through to the transport. |
| retries | `Int` | constant 0 | Passed on every call. |

No environment variables or settings keys.

