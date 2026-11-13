
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| integration-records-001 | clock-format, clock-now | `IntegrationClock.now()` (test `clock`) | The string ends with `Z` and contains `.` |
| integration-records-002 | column-encoding, json-text-columns, connection-table | Insert `IntegrationConnection(id: "c1", externalAccountId: "a@b.c", displayName: "A", status: .active, syncSettings: includeSpam true, scopes: "gmail.modify")` (test `connectionRoundTrip`) | Column `sync_settings` is text containing `includeSpam` |
| integration-records-003 | enum-text-columns, connection-status-cases | Same insert | Column `status` reads `active` and `typeof(status)` is `text` |
| integration-records-004 | column-decoding | Fetch the row by key `c1` (test `connectionRoundTrip`) | `externalAccountId == "a@b.c"`, `status == .active`, `syncSettings.includeSpam == true` |
| integration-records-005 | message-class-derived, json-text-columns, message-fields | `EmailMessage` with `labelIds: ["INBOX"]`, two `toAddresses`, one `EmailAttachmentRef`, no `mailClass`; insert and fetch (test `messageRoundTrip`) | Fetched record equals the original and `mailClass == .filed` |
| integration-records-006 | enum-text-columns | Same message | Column `mail_class` reads `filed` and `typeof(mail_class)` is `text` |
| integration-records-007 | message-class-explicit | `EmailMessage(... labelIds: ["INBOX"], mailClass: .trash ...)` | `mailClass == .trash` (follows from the initializer; no test asserts it) |
| integration-records-008 | connection-defaults | `IntegrationConnection(id:externalAccountId:displayName:scopes:)` only | `provider == "gmail"`, `serviceType == "messages"`, `status == .pending`, `syncSettings == MailSyncSettings.default` |
| integration-records-009 | action-log-defaults, action-log-fields | `ActionLog(id:connectionId:actionType:requestPayload:)` only | `provider == "gmail"`, `status == "pending"`, `idempotencyKey`, `result`, `error` all nil |
| integration-records-010 | label-defaults, provider-config-defaults | `EmailLabel` and `ProviderConfig` with required arguments only | Label has `sourceProvider "gmail"`, `type "user"`, `isDeleted` false; config has `providerId "gmail"`, `enabled` true |
| integration-records-011 | clock-defaults | Build any record with no timestamps | `createdAt` and `updatedAt` are strings in the `IntegrationClock` format |
| integration-records-012 | message-defaults, message-class-derived | `EmailMessage` with `labelIds: []` and no `mailClass` | Arrays default to empty and `mailClass == .archived` (the `MailClassifier` result for no filing label) |

