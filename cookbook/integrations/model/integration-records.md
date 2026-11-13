---
id: 888b7ba2-61f6-4251-88df-3586c5c86b1f
title: "IntegrationRecords"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The integration persistence records (connection, provider config, email message, label, action log), their snake_case column mapping and the shared ISO-8601 clock."
platforms:
  - swift
  - macos
  - ios
tags:
  - integrations
  - persistence
  - records
depends-on:
  - ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43
  - df121975-deb8-49a9-b023-0aadcb0923d8
related:
  - c19280fd-b80c-46f3-a6a7-0b60a0c90d91
  - 1157bca1-0d27-49e9-a989-d637505ba5f1
  - 39a27113-5478-468c-8417-a291d587aab6
references:
  - "https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb (GRDB: FetchableRecord, PersistableRecord and column strategies)"
approved-by: ""
approved-date: ""
---

# IntegrationRecords

## Overview

IntegrationRecords is the data model of the integrations store: five row types (`IntegrationConnection`, `ProviderConfig`, `EmailMessage`, `EmailLabel`, `ActionLog`), the small value types they embed (`ConnectionStatus`, `LabelColor`, `EmailAttachmentRef`), the `IntegrationRecord` protocol that gives every row the same column-naming rules, and `IntegrationClock`, the one source of timestamp strings. It holds no I/O of its own; the store and the sync worker read and write these rows. It embeds `MailSyncSettings` and `MailClass` from the sibling mail model files and calls `MailClassifier.classify(labelIds:)` when a message is built without a class.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a data model, not a visual component.

## States

Not applicable — this is a data model, not a visual component.

## Accessibility

Not applicable — this is a data model, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| integration-records-001 | clock-format, clock-now | `IntegrationClock.now()` (test `clock`) | The string matches `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$` (the test asserts only that it ends with `Z` and contains `.`) |
| integration-records-002 | column-encoding, json-text-columns, connection-table | Insert `IntegrationConnection(id: "c1", externalAccountId: "a@b.c", displayName: "A", status: .active, syncSettings: includeSpam true, scopes: "gmail.modify")` (test `connectionRoundTrip`) | Column `sync_settings` is text containing `includeSpam` |
| integration-records-003 | enum-text-columns, connection-status-cases | Same insert | Column `status` reads `active` and `typeof(status)` is `text` |
| integration-records-004 | column-decoding | Fetch the row by key `c1` (test `connectionRoundTrip`) | `externalAccountId == "a@b.c"`, `status == .active`, `syncSettings.includeSpam == true` |
| integration-records-005 | message-class-derived, json-text-columns, message-fields | `EmailMessage` with `labelIds: ["INBOX"]`, two `toAddresses`, one `EmailAttachmentRef`, no `mailClass`; insert and fetch (test `messageRoundTrip`) | Fetched record equals the original and `mailClass == .filed` |
| integration-records-006 | enum-text-columns | Same message | Column `mail_class` reads `filed` and `typeof(mail_class)` is `text` |
| integration-records-007 | message-class-explicit | `EmailMessage(... labelIds: ["INBOX"], mailClass: .trash ...)` | `mailClass == .trash` (follows from the initializer; no test asserts it) |
| integration-records-008 | connection-defaults | `IntegrationConnection(id:externalAccountId:displayName:scopes:)` only | `provider == "gmail"`, `serviceType == "messages"`, `status == .pending`, `syncSettings == MailSyncSettings.default` (untested) |
| integration-records-009 | action-log-defaults, action-log-fields | `ActionLog(id:connectionId:actionType:requestPayload:)` only | `provider == "gmail"`, `status == "pending"`, `idempotencyKey`, `result`, `error` all nil (untested) |
| integration-records-010 | label-defaults, provider-config-defaults | `EmailLabel` and `ProviderConfig` with required arguments only | Label has `sourceProvider "gmail"`, `type "user"`, `isDeleted` false; config has `providerId "gmail"`, `enabled` true (untested) |
| integration-records-011 | clock-defaults | Build any record with no timestamps | `createdAt` and `updatedAt` are strings in the `IntegrationClock` format (untested) |
| integration-records-012 | message-defaults, message-class-derived | `EmailMessage` with `labelIds: []` and no `mailClass` | Arrays default to empty and `mailClass == .archived` (the `MailClassifier` result for no filing label) (untested) |
| integration-records-013 | label-table | `EmailLabel.databaseTableName` | `"integration_email_labels"` (untested) |
| integration-records-014 | provider-config-table | `ProviderConfig.databaseTableName` | `"integration_provider_configs"` (untested) |
| integration-records-015 | action-log-table | `ActionLog.databaseTableName` | `"integration_action_logs"` (untested) |
## Edge Cases

- **Optional columns null**: a nil optional property (`deletedAt`, `lastError`, `bodyText`, `color`) is stored as SQL NULL and read back as nil.
- **Empty collections**: an empty `toAddresses`, `ccAddresses`, `labelIds` or `attachments` is the default and round-trips as an empty array.
- **Empty label ids**: an `EmailMessage` built with `labelIds: []` and no `mailClass` gets `.archived`, because `MailClassifier.classify` finds no filing label.
- **Unknown enum text**: a stored `status` or `mail_class` that is not a known raw value fails to decode through the synthesized `Codable`; the records add no fallback, so the fetch raises the decoding error to the caller.
- **Missing table or column**: a missing table raises the GRDB error to the caller. A row lacking a column that maps to a required property fails to decode with a decoding error; a column that maps to an optional property reads as nil. The schema lives in the store, not here.
- **Free-string fields**: `EmailLabel.type` and `ActionLog.status` accept any text; the documented value sets are comments, not checks.
- **Concurrent access**: records are `Sendable` value types with no shared mutable state, so concurrent use needs no ordering rule; serialisation of database writes belongs to the store.
- **Offline or network failure**: not applicable; the records never touch the network.
- **Boundary values**: `size`, `messagesTotal` and `messagesUnread` are unbounded `Int`s with no range check; range limits for sync settings belong to `MailSyncSettings`.
- **Timestamp text order**: timestamps sort and compare as text only because the clock always emits exactly three fractional digits (**clock-format**); a string with seven digits or none would break the order.
- **Clock sampling**: default timestamps are read at each initializer call, so two records built in quick succession can differ in the fractional digits.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `provider` | String | `"gmail"` | Provider tag on connections, messages and action logs |
| `providerId` | String | `"gmail"` | Provider tag on `ProviderConfig` |
| `sourceProvider` | String | `"gmail"` | Provider tag on `EmailLabel` |
| `serviceType` | String | `"messages"` | Service on `IntegrationConnection` |
| `status` (connection) | ConnectionStatus | `.pending` | Initial connection state |
| `status` (action log) | String | `"pending"` | Initial action state |
| `syncSettings` | MailSyncSettings | `.default` | Mirroring settings stored as JSON text |
| `enabled` | Bool | `true` | Provider config switch |
| `type` | String | `"user"` | Label kind |
| `createdAt`, `updatedAt` | String | `IntegrationClock.now()` | Timestamps |

## Deep Linking

Not applicable: the records define no URLs or routes.

## Localization

Not applicable: the records contain no user-facing strings.

## Accessibility Options

Not applicable: the records have no visual surface, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: the records hold a user's mail data (`fromAddress`, `toAddresses`, `ccAddresses`, `subject`, `snippet`, `bodyText`, `bodyHtml`, attachment names), the connected account (`externalAccountId`, `displayName`), the granted `scopes`, and the OAuth `clientId` on `ProviderConfig`.
- **Storage**: the records define the columns only; they hold no tokens or secrets, and the database file and its protection belong to the store.
- **Transmission**: the records do not transmit anything.
- **Retention**: `deletedAt` and `isDeleted` mark soft deletion on the rows that carry them; `ActionLog` has no deletion marker. When rows are purged is decided by the store.

## Logging

Not applicable: the source contains no log calls.

## Platform Notes

- **SwiftUI**: Not a view; the structs are `Equatable` value types, so a SwiftUI view model can hold and diff them directly. Built on GRDB's `FetchableRecord` and `PersistableRecord` and its snake_case column strategies.
- **Compose**: Use Kotlin data classes with Room `@Entity` and `@ColumnInfo(name = "...")` snake_case names, `TypeConverter`s for the JSON text columns (a `kotlinx.serialization` encoder per type), and enum converters that store the raw name as TEXT.
- **React/Web**: Use TypeScript interfaces with camelCase keys and a row mapper converting snake_case; store JSON columns with `JSON.stringify` and `JSON.parse`, and a string-literal union for `ConnectionStatus` and `MailClass`. `Date.toISOString()` yields UTC with milliseconds and a `Z` suffix, matching the clock format.
- **AppKit / UIKit**: Same Swift source as above; the model has no AppKit or UIKit dependency, so macOS and iOS share it unchanged.
- **WinUI 3**: Use C# `record` types (or classes implementing `INotifyPropertyChanged` if bound directly to XAML) over `Microsoft.Data.Sqlite` or EF Core with snake_case column names (`HasColumnName` or a snake-case naming convention). Map `List<string>`, `MailSyncSettings`, `List<EmailAttachmentRef>` and `LabelColor` to TEXT with `System.Text.Json` through EF Core value converters, and `ConnectionStatus` and `MailClass` to TEXT through `HasConversion<string>()`. Produce timestamps with `DateTime.UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture)` to match the ISO-8601 UTC format. C# records are immutable by default, unlike the mutable Swift `var` fields, so a port should choose deliberately between `init` properties with `with` expressions and mutable classes. Run store access on a background `Task` so it never blocks the UI thread.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Model/IntegrationRecords.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Persist non-column properties as JSON text through the `Codable` conformance instead of writing per-record encode code.
**Rationale**: GRDB stores these `Codable` values as JSON TEXT on its own, so adding a field to a nested type such as `MailSyncSettings` changes no column and needs no schema migration or mapping code.
**Approved**: pending

**Decision**: Cache `mailClass` on `EmailMessage`, derived once in the initializer when not supplied.
**Rationale**: Queries and tombstoning read the class directly instead of re-running the classifier over `labelIds` for every row; the explicit parameter lets the store restore a stored class unchanged even if the classifier rules later change.
**Approved**: pending

**Decision**: Keep `EmailLabel.type`, `ActionLog.status` and `ActionLog.requestPayload` as plain strings rather than enums or typed payloads.
**Rationale**: The value sets are documented only in comments, and this version keeps them as strings. Enum text that is not a known raw value fails to decode the whole row, so a new provider-side label type or action state would make existing rows unreadable. A port may promote them to enums stored as raw-value TEXT, as `ConnectionStatus` is, once the sets are closed.
**Approved**: pending

**Decision**: Store every timestamp as an ISO-8601 UTC string with fractional seconds.
**Rationale**: A fixed-width UTC string with three fractional digits sorts and compares correctly as text in SQLite, so queries and cursors need no date parsing.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | partial | privacy-and-data |

The records hold only shape and mapping, with persistence, classification and sync in other files, so separation of concerns passes. `IntegrationRecordsTests` covers the connection and message round trips and the clock, but not `ProviderConfig`, `EmailLabel`, `ActionLog` or the defaults, so unit test coverage is partial. Data integrity is partial because free-string fields (`EmailLabel.type`, `ActionLog.status`) are not validated here and constraints live in the store schema. Secure data storage is partial because the records carry message bodies and addresses in plain columns while protection of the database file is outside this file.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
