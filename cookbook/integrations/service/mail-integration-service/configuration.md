
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `IntegrationsStore` | required | Connections, provider config, labels, messages, tombstones and action logs. |
| secrets | `any SecretStoring` | required | Keychain wrapper for the client secret and per-connection credentials. |
| signIn | `any GoogleSignInFlow` | `AppAuthGoogleSignIn()` | Runs the browser OAuth flow and returns a `GoogleCredential`. |
| tokenEndpoint | `any GoogleTokenEndpoint` | `URLSessionGoogleTokenEndpoint()` | Refreshes and revokes Google tokens. |
| makeAPI | closure from an access-token provider to `any GmailAPI` | builds `GmailRESTClient` | Factory for the Gmail client used by syncs, searches, threads and writes. |
| now | `@Sendable () -> Date` | `Date.init` | Clock for due-ness, window starts and the sync worker. |
| tick | `Duration` | 60 seconds | Interval between scheduler passes (`start`). |
| timeout | `Duration` | 5 seconds | Longest `stop` waits for cancelled syncs. |
| refetchConcurrency | constant | 8 | Messages re-read from Gmail at once. |
| MailSyncSettings | per connection | `includeArchived` false, `includeSpam` false, `includeTrash` false, `windowDays` 30, `pollIntervalMinutes` 15 | Which mail classes and how many days the mirror keeps and how often it polls. |
| MailMessageFilter.limitRange | constant | 1...500, default 50 | Page size bounds. |

There are no environment variables or settings keys read by this file.

