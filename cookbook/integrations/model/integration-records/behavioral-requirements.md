
### Clock

- **clock-format**: `IntegrationClock.string(from:)` MUST return an ISO-8601 string in UTC with exactly three fractional digits, matching `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$`, the format every integration column uses. A port that emits seven digits or none does not conform.
- **clock-now**: `IntegrationClock.now()` MUST return `string(from:)` applied to the current date.
- **clock-defaults**: Every record initializer MUST default `createdAt` and `updatedAt` to `IntegrationClock.now()`.

### Shared persistence rules

- **record-protocol**: Every row type MUST conform to `IntegrationRecord`, which requires `Codable`, `FetchableRecord`, `PersistableRecord`, `Sendable` and `Equatable`.
- **column-decoding**: A record MUST read its columns converting snake_case column names to camelCase property names.
- **column-encoding**: A record MUST write its properties converting camelCase property names to snake_case column names.
- **json-text-columns**: A property that is not a plain column value (`[String]`, `MailSyncSettings`, `[EmailAttachmentRef]`, `LabelColor`) MUST be stored as JSON text, with no per-record code.
- **enum-text-columns**: `ConnectionStatus` and `MailClass` values MUST be stored as plain text holding the raw value, not as JSON or a number.
- **sendable-records**: Every row type and embedded value type MUST be `Sendable`, so records cross actor boundaries by value.

### Value types

- **connection-status-cases**: `ConnectionStatus` MUST have exactly the cases `active`, `error`, `revoked` and `pending`, each with its name as raw value.
- **label-color-optional**: `LabelColor` MUST carry two optional strings, `textColor` and `backgroundColor`, both defaulting to nil (Gmail's label color shape).
- **attachment-ref-fields**: `EmailAttachmentRef` MUST carry `attachmentId`, `filename`, `mimeType` and `size` (an `Int`), all required.

### IntegrationConnection

- **connection-table**: `IntegrationConnection` MUST map to the table `integration_connections`.
- **connection-fields**: It MUST carry `id`, `provider`, `serviceType`, `externalAccountId`, `displayName`, `status`, `lastSyncAt`, `lastError`, `syncCursor`, `syncSettings`, `scopes`, `createdAt`, `updatedAt` and `deletedAt`; `lastSyncAt`, `lastError`, `syncCursor` and `deletedAt` are optional.
- **connection-defaults**: Its initializer MUST default `provider` to `"gmail"`, `serviceType` to `"messages"`, `status` to `.pending`, and `syncSettings` to `MailSyncSettings.default`. `id`, `externalAccountId`, `displayName` and `scopes` are required.

### ProviderConfig

- **provider-config-table**: `ProviderConfig` MUST map to the table `integration_provider_configs`.
- **provider-config-fields**: It MUST carry `id`, `providerId`, `name`, `clientId`, `enabled`, `createdAt`, `updatedAt` and an optional `deletedAt`.
- **provider-config-defaults**: Its initializer MUST default `providerId` to `"gmail"` and `enabled` to true.

### EmailMessage

- **message-table**: `EmailMessage` MUST map to the table `integration_email_messages`.
- **message-fields**: It MUST carry `id`, `connectionId`, `provider`, `externalId`, `threadId`, `fromAddress`, `toAddresses`, `ccAddresses`, `subject`, `snippet`, optional `bodyText`, optional `bodyHtml`, `labelIds`, `internalDate`, optional `historyId`, `attachments`, `mailClass`, `isDeleted`, `createdAt`, `updatedAt` and optional `deletedAt`.
- **message-defaults**: Its initializer MUST default `provider` to `"gmail"`, `toAddresses`, `ccAddresses`, `labelIds` and `attachments` to empty arrays, and `isDeleted` to false.
- **message-class-derived**: When the initializer is given no `mailClass`, it MUST set it to `MailClassifier.classify(labelIds:)` of the given `labelIds`.
- **message-class-explicit**: When the initializer is given a `mailClass`, it MUST keep that value and not re-derive it.
- **message-class-cached**: The record MUST NOT recompute `mailClass` after construction; it is stored on the row (see Design Decisions).

### EmailLabel

- **label-table**: `EmailLabel` MUST map to the table `integration_email_labels`.
- **label-fields**: It MUST carry `id`, `connectionId`, `externalId`, `sourceProvider`, `name`, optional `parentName`, `type`, optional `color` (a `LabelColor`), optional `messagesTotal`, optional `messagesUnread`, `isDeleted`, `createdAt`, `updatedAt` and optional `deletedAt`.
- **label-defaults**: Its initializer MUST default `sourceProvider` to `"gmail"`, `type` to `"user"` and `isDeleted` to false.
- **label-type-values**: The record MUST NOT validate `EmailLabel.type`; it accepts any string, though the source documents `"system"` or `"user"`.

### ActionLog

- **action-log-table**: `ActionLog` MUST map to the table `integration_action_logs`.
- **action-log-fields**: It MUST carry `id`, `connectionId`, `provider`, `actionType`, optional `idempotencyKey`, `requestPayload` (JSON text), `status`, optional `result`, optional `error`, `createdAt` and `updatedAt`. It has no `deletedAt`.
- **action-log-defaults**: Its initializer MUST default `provider` to `"gmail"` and `status` to `"pending"`.
- **action-log-status-values**: The record MUST NOT validate `ActionLog.status`; it accepts any string, though the source documents `"pending"`, `"ok"` or `"error"`.

### Field types

Column names are the snake_case form of the property name. Storage is plain (a native SQLite value), JSON TEXT, or enum TEXT (the raw value).

| Record | Property: Swift type (storage) |
|--------|-------------------------------|
| `IntegrationConnection` | `id`, `provider`, `serviceType`, `externalAccountId`, `displayName`, `scopes` (one string, not an array), `createdAt`, `updatedAt`: `String` (plain); `status`: `ConnectionStatus` (enum TEXT); `lastSyncAt`, `lastError`, `syncCursor`, `deletedAt`: `String?` (plain); `syncSettings`: `MailSyncSettings` (JSON TEXT) |
| `ProviderConfig` | `id`, `providerId`, `name`, `clientId`, `createdAt`, `updatedAt`: `String` (plain); `enabled`: `Bool` (plain); `deletedAt`: `String?` (plain) |
| `EmailMessage` | `id`, `connectionId`, `provider`, `externalId`, `threadId`, `fromAddress`, `subject`, `snippet`, `internalDate`, `createdAt`, `updatedAt`: `String` (plain); `bodyText`, `bodyHtml`, `historyId`, `deletedAt`: `String?` (plain); `toAddresses`, `ccAddresses`, `labelIds`: `[String]` (JSON TEXT); `attachments`: `[EmailAttachmentRef]` (JSON TEXT); `mailClass`: `MailClass` (enum TEXT); `isDeleted`: `Bool` (plain) |
| `EmailLabel` | `id`, `connectionId`, `externalId`, `sourceProvider`, `name`, `type`, `createdAt`, `updatedAt`: `String` (plain); `parentName`, `deletedAt`: `String?` (plain); `color`: `LabelColor?` (JSON TEXT); `messagesTotal`, `messagesUnread`: `Int?` (plain); `isDeleted`: `Bool` (plain) |
| `ActionLog` | `id`, `connectionId`, `provider`, `actionType`, `requestPayload` (JSON text held in a string), `status`, `createdAt`, `updatedAt`: `String` (plain); `idempotencyKey`, `result`, `error`: `String?` (plain) |

### Concurrency and side effects

- **no-side-effects**: Constructing a record MUST NOT touch the database, files or network; the only environmental read is the clock for default timestamps.
- **value-semantics**: Records are structs with `var` properties so a caller can change a field on a copy (a status, an `updatedAt`) and write the copy back; they are `Sendable`, and the source declares no locking, so a caller mutating a copy MUST NOT affect other copies.

