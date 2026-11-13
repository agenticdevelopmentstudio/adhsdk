
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `transport` | `@Sendable (Data) async throws -> Data` | none, required | Sends request bytes to a `MailIntegrationService` and returns the reply bytes; XPC, a socket or an in-process call. |
| `MailMessageFilter.limitRange` | `ClosedRange<Int>` | `1...500` | Bounds that `limit` is clamped to. |
| `MailMessageFilter.defaultLimit` | `Int` | `50` | The `limit` when none is given or decoded. |
| `MailProviderStatus.secretSuffixLength` | `Int` | `5` | How many trailing characters of the client secret may be shown. |
| `includeBodies` (filter, `getThread`) | `Bool` | `false` | Whether messages carry `bodyText` and `bodyHtml`. |
| `from` (`moveMessages`) | `[String]?` | `nil` | Labels to remove; nil means INBOX, or nothing when the destination is INBOX. |

There are no environment variables or settings keys.

