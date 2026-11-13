
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` | `GoogleOAuthClientConfig` | required | Desktop-app OAuth client id and secret, passed to `signIn`, `refresh` and `accessToken` |
| `timeout` | `Duration` | 300 seconds | Sign-in deadline for `AppAuthGoogleSignIn` |
| `successURL` | `URL?` | nil | Where the browser is sent after the redirect, typically the host app's URL scheme |
| `now` | `@Sendable () -> Date` | `Date.init` | Clock for `AppAuthGoogleSignIn` and `GoogleTokenProvider` |
| `session` | `URLSession` | `.shared` | Session used by `URLSessionGoogleTokenEndpoint` |
| `secrets` | `any SecretStoring` | required | Keychain abstraction used by `GoogleTokenProvider` |
| `endpoint` | `any GoogleTokenEndpoint` | required | Token endpoint used by `GoogleTokenProvider` |
| Refresh margin | `TimeInterval` | 60 seconds | Constant; not caller-configurable |
| Fallback lifetime | `TimeInterval` | 3600 seconds | Constant; used when Google reports no expiry |
| Credential key | string | `integrations.gmail.<connectionId>.credential` | Keychain key per connection |
| Client secret key | string | `integrations.gmail.oauth-client-secret` | Public constant for hosts that store the client secret |

