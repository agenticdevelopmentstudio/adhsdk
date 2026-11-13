---
id: df121975-deb8-49a9-b023-0aadcb0923d8
title: "MailSyncSettings"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Per-connection mail sync settings: which mail classes are mirrored, the look-back window in days and the poll interval."
platforms:
  - swift
  - macos
  - ios
tags:
  - integrations
  - mail
  - settings
depends-on:
  - ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43
  - 351e3bf8-b137-4f59-94de-c769aa8b0666
related:
  - 888b7ba2-61f6-4251-88df-3586c5c86b1f
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references: []
approved-by: ""
approved-date: ""
---

# MailSyncSettings

## Overview

MailSyncSettings is a small value type that says which mail classes a connection mirrors, how many days back it looks, and how often it polls. It holds five fields (`includeArchived`, `includeSpam`, `includeTrash`, `windowDays`, `pollIntervalMinutes`), a static `default`, two range constants, a classification gate `allows(_:)` and a range check `validated()`. It does no I/O. The connection record stores it as JSON (see the integration records recipe (cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f)) and the settings screen edits it. The mail integration service (cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) calls `validated()` as the first step of its settings update, so an invalid value is rejected before any stored data changes; this is the caller's contract and this type does not enforce it. When syncing, the service reads `allows(_:)` to decide which message classes to keep or tombstone, `windowDays` to compute the look-back start and tombstone older rows, and `pollIntervalMinutes` times 60 seconds as the minimum time between sync attempts per connection. It depends on `MailClass` (cookbook:ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43), with cases `filed`, `archived`, `spam` and `trash`, and on `IntegrationError.invalidSettings(String)` (cookbook:351e3bf8-b137-4f59-94de-c769aa8b0666).

## Behavioral Requirements

### Shape

- **fields**: MailSyncSettings MUST expose the mutable fields `includeArchived`, `includeSpam` and `includeTrash` (Bool) and `windowDays` and `pollIntervalMinutes` (Int).
- **value-semantics**: MailSyncSettings MUST be an `Equatable`, `Codable` and `Sendable` value type, so two instances with equal fields compare equal.
- **default-values**: The static `default` MUST have all three include flags false, `windowDays` 30 and `pollIntervalMinutes` 15.
- **memberwise-init-defaults**: The memberwise initializer MUST default each parameter to the same value as `default`, so omitting every argument yields `default`.
- **range-constants**: MailSyncSettings MUST publish `windowDaysRange` as 1 through 3650 and `pollIntervalRange` as 1 through 1440, both inclusive.

### Decoding

- **decode-keys**: Decoding MUST read the five keys `includeArchived`, `includeSpam`, `includeTrash`, `windowDays` and `pollIntervalMinutes`, spelled exactly so, and the encoded form MUST use the same five keys.
- **decode-lenient**: Decoding MUST take the value from `default` for each key that is absent, so an empty JSON object decodes to `default`.
- **decode-null-key**: Decoding MUST treat a key present with a JSON null the same as an absent key, so a stored row whose field was cleared still loads instead of failing.
- **decode-partial**: Decoding MUST keep the keys that are present and default only the missing ones.
- **decode-ignore-unknown**: Decoding MUST ignore keys other than the five, so a stored row carrying extra keys still loads and decodes to the same values.
- **decode-wrong-type**: Decoding MUST propagate the decoder's error when a present key has the wrong type (for example a string for `windowDays`); the source does not catch it.
- **decode-no-range-check**: Decoding MUST NOT validate ranges, so an out-of-range number decodes unchanged and is rejected only when `validated()` is called.
- **init-no-range-check**: The memberwise initializer MUST NOT validate ranges.

### Classification gate

- **allows-filed**: `allows(_:)` MUST return true for `.filed` regardless of the three flags.
- **allows-flagged**: `allows(_:)` MUST return `includeArchived` for `.archived`, `includeSpam` for `.spam` and `includeTrash` for `.trash`.

### Validation

- **validated-window**: `validated()` MUST throw `IntegrationError.invalidSettings` with the message `windowDays must be 1–3650, got <value>` when `windowDays` is outside 1 through 3650.
- **validated-poll**: `validated()` MUST throw `IntegrationError.invalidSettings` with the message `pollIntervalMinutes must be 1–1440, got <value>` when `pollIntervalMinutes` is outside 1 through 1440.
- **validated-order**: `validated()` MUST check `windowDays` before `pollIntervalMinutes`, so when both are invalid the error names `windowDays`.
- **validated-returns-self**: `validated()` MUST return the unchanged instance when both numbers are in range, accepting the boundary values 1 and 3650 for `windowDays` and 1 and 1440 for `pollIntervalMinutes`.
- **validated-no-clamp**: `validated()` MUST NOT clamp or repair a bad value; it only accepts or throws.

### Ordering and concurrency

- **no-shared-state**: MailSyncSettings MUST hold no shared mutable state; as a `Sendable` value its copies move freely between threads and the type adds no ordering rule.

### Persistence and side effects

- **no-side-effects**: Every operation MUST be a pure function of the instance fields; none touches files, the network, processes or notifications.
- **persisted-as-json**: MailSyncSettings MUST be persisted through its `Codable` conformance as JSON text, which the connection record stores in a column (cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f).

## Appearance

Not applicable — this is a settings value type, not a visual component.

## States

Not applicable — this is a settings value type, not a visual component.

## Accessibility

Not applicable — this is a settings value type, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-sync-settings-001 | default-values | Read `MailSyncSettings.default` (test `defaultValues`) | Three flags false, `windowDays` 30, `pollIntervalMinutes` 15 |
| mail-sync-settings-002 | memberwise-init-defaults | `MailSyncSettings()` | Equals `default` |
| mail-sync-settings-003 | allows-filed, allows-flagged | `default.allows(.filed)`, `.archived`, `.spam`, `.trash` (test `allows`) | true, false, false, false |
| mail-sync-settings-004 | allows-flagged | All three flags set true, query `.archived`, `.spam`, `.trash` (test `allows`) | true for each |
| mail-sync-settings-005 | validated-window | `windowDays` 0, then 3651, with `pollIntervalMinutes` 15 (test `rejects`) | Each throws `IntegrationError.invalidSettings` with message `windowDays must be 1–3650, got 0`, then `... got 3651` |
| mail-sync-settings-006 | validated-poll | `pollIntervalMinutes` 0, then 1441, with `windowDays` 30 (test `rejects`) | Each throws `IntegrationError.invalidSettings` with message `pollIntervalMinutes must be 1–1440, got 0`, then `... got 1441` |
| mail-sync-settings-007 | validated-returns-self | `default`; then (3650, 1440); then (1, 1) (test `accepts`) | `validated()` returns an equal value each time, no throw |
| mail-sync-settings-008 | decode-lenient | JSON `{}` (test `lenientDecode`) | Decodes to `default` |
| mail-sync-settings-009 | decode-partial, decode-keys | JSON `{"includeSpam":true,"windowDays":10}` (test `partialDecode`) | `includeSpam` true, `windowDays` 10, `pollIntervalMinutes` 15 |
| mail-sync-settings-010 | validated-window, validated-order | `windowDays` 0 and `pollIntervalMinutes` 0 | Throws with message `windowDays must be 1–3650, got 0` (derived from the source, no test) |
| mail-sync-settings-011 | decode-no-range-check | JSON `{"windowDays":5000}` | Decodes with `windowDays` 5000; `validated()` then throws (derived from the source, no test) |
| mail-sync-settings-012 | decode-wrong-type | JSON `{"windowDays":"x"}` | Decoding throws a `DecodingError` (derived from the source, no test) |
| mail-sync-settings-013 | decode-null-key | JSON `{"windowDays":null}` | `windowDays` is 30 (derived from the source, no test) |
| mail-sync-settings-014 | decode-ignore-unknown | JSON `{"foo":1}` | Decodes to `default` (derived from the source, no test) |
| mail-sync-settings-015 | validated-window | `windowDays` -1, with `pollIntervalMinutes` 15 | Throws with message `windowDays must be 1–3650, got -1` (derived from the source, no test) |
| mail-sync-settings-016 | validated-poll | `pollIntervalMinutes` -1, with `windowDays` 30 | Throws with message `pollIntervalMinutes must be 1–1440, got -1` (derived from the source, no test) |
## Edge Cases

- **Empty object**: `{}` MUST decode to `default`; the doc comment says a missing key takes its default.
- **Null key**: A key set to null MUST take the default, the same as a missing key.
- **Unknown extra keys**: Keys other than the five MUST be ignored (decode-ignore-unknown).
- **Wrong-typed value**: A key with the wrong JSON type MUST make decoding throw; leniency covers absent keys only.
- **Boundary values**: `windowDays` of 1 and 3650 and `pollIntervalMinutes` of 1 and 1440 MUST pass validation; 0, 3651 and 1441 MUST fail.
- **Negative numbers**: A negative `windowDays` or `pollIntervalMinutes` is outside its range and MUST fail validation with the offending value in the message.
- **Both numbers invalid**: Only the `windowDays` error is raised, because it is checked first.
- **Unvalidated instances**: An instance built by decoding or the initializer can hold out-of-range numbers; a caller that skips `validated()` carries them forward. The service validates on update, and this type does not stop other callers.
- **Concurrent access**: Not applicable; the type is a `Sendable` value with no shared state, so each thread works on its own copy.
- **Offline or error states from dependencies**: Not applicable; the type has no network, file or database dependency. The only error it raises is `IntegrationError.invalidSettings`.
- **Cancellation and timeouts**: Not applicable; every operation is synchronous and returns immediately.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `includeArchived` | Bool | false | Also mirror archived mail (`MailClass.archived`) |
| `includeSpam` | Bool | false | Also mirror spam (`MailClass.spam`) |
| `includeTrash` | Bool | false | Also mirror trash (`MailClass.trash`) |
| `windowDays` | Int | 30 | Look-back window in days; valid range 1 through 3650 |
| `pollIntervalMinutes` | Int | 15 | Minutes between polls; valid range 1 through 1440 |

## Deep Linking

Not applicable: MailSyncSettings is a data type with no screen or URL, so it has no entry point to link to.

## Localization

Not applicable: the type renders no text of its own. The two validation messages are English strings built into `IntegrationError.invalidSettings`, whose `errorDescription` prefixes them with `Invalid sync settings: `; they are not localized, and the en-dash and wording are fixed in source.

## Accessibility Options

Not applicable: MailSyncSettings has no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no feature flag; the include flags are user data, not rollout switches.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

Not applicable: the type holds only booleans and two counts, with no address, credential or message content, and it makes no transmission of its own. The record that embeds it is covered by the records recipe.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Integrations/Model/MailSyncSettings.swift`, a Foundation-only struct with a hand-written `init(from:)` using `decodeIfPresent` and a private `CodingKeys`. As an `Equatable` value it can back `@State` or an observable model directly, and the settings screen can bind each field to a `Toggle` or `Stepper` and call `validated()` before saving.
- **Compose**: Use a Kotlin data class with default parameter values equal to `default`. With `kotlinx.serialization`, set defaults on each property and use `Json { coerceInputValues = true; ignoreUnknownKeys = true }` so absent keys default; a JSON null needs `coerceInputValues` and non-null types, and a wrong-typed value still throws `SerializationException`. Implement `validated()` with `require` or a custom exception carrying the same message.
- **React/Web**: Use a TypeScript interface with the five camelCase keys, a `defaultMailSyncSettings` constant, and a decode function that spreads parsed JSON over the default after dropping null values; `JSON.parse` does not reject wrong types, so check `typeof` and throw to match the source. `validated` is a function that throws an `Error` with the same message, and `allows` is a switch over a string-literal union of the four classes.
- **AppKit / UIKit**: Same Swift source; the type imports only Foundation, so macOS and iOS share it unchanged and an AppKit or UIKit settings screen uses it through a view model.
- **WinUI 3**: Use a C# `record` (positional properties with the default values) in the Windows App SDK app, serialized with `System.Text.Json`. `System.Text.Json` leaves a missing property at its initializer value, which matches the lenient decode; a JSON null for a non-nullable `int` or `bool` throws a `JsonException`, so add a custom `JsonConverter` or nullable properties with `?? default` to match the source's null handling, and a wrong-typed value throws `JsonException`, matching the source. Implement `Allows(MailClass)` as a `switch` expression and `Validated()` as a method that throws a custom exception (or `ArgumentOutOfRangeException`) with the same message. For two-way binding in XAML, use a view model implementing `INotifyPropertyChanged` that wraps the record, since records are immutable by default unlike the mutable Swift `var` fields. Persist it as a JSON string through `Windows.Storage.ApplicationData` settings or an EF Core value converter.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Model/MailSyncSettings.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Decode each key leniently with a default instead of failing on a missing key.
**Rationale**: Old rows must keep loading after a field is added, and hand-edited JSON should not brick a connection. Defaulting per key keeps every row readable.
**Approved**: pending

**Decision**: Keep range checking in `validated()` and out of decoding and the initializer.
**Rationale**: A stored row with a bad number still loads and can be shown and corrected, while the service calls `validated()` at the point a user's change is accepted. The cost is that an unvalidated instance can carry out-of-range numbers, and `validated()` returns the same type, so nothing in the type system tells a checked instance from an unchecked one. A distinct validated type or a throwing initializer was considered and rejected: either would make decoding fail on a bad stored row, which is the case this design keeps loadable.
**Approved**: pending

**Decision**: `.filed` is always allowed and has no flag.
**Rationale**: The user's filed mail is the core of what a connection exists to mirror, so turning it off would make the connection pointless; only the optional classes (archived, spam, trash) are opt-in.
**Approved**: pending

**Decision**: Window of 1 to 3650 days and poll interval of 1 to 1440 minutes.
**Rationale**: The bounds are fixed in `windowDaysRange` and `pollIntervalRange`; 3650 days is ten years and 1440 minutes is one day. The source gives no further reason for the numbers.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

The type holds shape, defaults, the class gate and the range check, with persistence and sync elsewhere, so separation of concerns passes. `MailSyncSettingsTests` covers the defaults, `allows`, both ranges and their boundaries, the empty-object decode and the partial decode, but not null keys, wrong-typed keys, unknown keys or the error message text, so unit test coverage is partial. Error handling passes because `validated()` throws a typed error with the offending value, and decoding errors propagate. Data integrity is partial because decoding and the initializer accept out-of-range numbers and the guarantee depends on callers invoking `validated()`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
