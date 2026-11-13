
Every user-facing error is a hardcoded English string, not a localised key.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline) | `bad request` | `MailClient.badRequest`, an undecodable request |
| none (inline) | `Could not save the OAuth client secret to the Keychain` | Import cannot write the secret |
| none (inline) | `Could not read the OAuth client secret: <cause>` | Keychain read failure |
| none (inline) | `a query can't be combined with any-label; write {label:a label:b} in the query` | Search with `anyLabels` |
| none (inline) | `invalid cursor: <cursor>` | Malformed mirror or search cursor |
| none (inline) | `invalid since: <text>` / `invalid until: <text>` | Search bound not ISO 8601 |
| none (inline) | `unknown label: <value>` | Label resolution failure |
| none (inline) | `account <email> is not ready to sync` | `syncNow` on a non-syncable account |
| none (inline) | `account <email> was removed` | Label refresh after the account vanished |
| none (inline) | `cannot move to <destination>: it is also a label to move from` | Move conflict |
| none (inline) | `labels applied; refreshing messages failed: <message>` | Re-read failed after a write |
| none (inline) | `No connected account matches “<account>”` | `IntegrationError.unknownAccount`, an account that matches no id or email |
| none (inline) | `Invalid sync settings: <reason>` (for example `windowDays must be 1–3650, got <n>`) | `IntegrationError.invalidSettings`, a refused `updateSettings` |
| none (inline) | `encoding failed` | Response could not be encoded |

The `IntegrationError` cases (`notConfigured`, `unknownAccount`, `revoked` and the rest) supply their own English `errorDescription` in the Model layer.

