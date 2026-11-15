---
id: d525cc69-4d2c-4d17-a570-f71e8d5aa273
title: "Work Tracking Preferences"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The settings-store seam and the load, save and Accessibility-answer helpers that read and write work-tracking preferences, normalized on every pass."
platforms:
  - swift
  - macos
tags:
  - work-tracking
  - foundation
  - settings
depends-on: []
related:
  - a8bfcd0b-0759-4801-aaf6-a14d7aa3fe49
  - 0175f0bb-f4bd-4f72-94c2-57b087ad9df9
references: []
approved-by: ""
approved-date: ""
---

# Work Tracking Preferences

## Overview

`WorkTrackingPrefs` is a caseless enum of static functions that reads and writes the work-tracking settings through `WorkTrackingSettingsStore`, a three-requirement protocol the host conforms its database to (its doc comment names Stenographer's SQLite `DatabaseManager` and says the requirements mirror `BillingPersistence`). Keys come from `WorkTrackingSettingsKeys`. Per the doc comment, everything written is normalized first (sorted, de-duplicated ids; retention clamped) and everything read is normalized too, "so a hand-edited row still means the nearest valid value". The same file also stores the answer of the last Accessibility check together with the code signature it was given under, and decides how far a stored answer may be trusted. The value types (`WorkTrackingPreferences`, `WorkTrackingAccessibility`) and the key names live in `WorkTrackingModels.swift`; text parsing is the shared [adhsdk.ingredient.foundation.raw-setting](cookbook:a8bfcd0b-0759-4801-aaf6-a14d7aa3fe49) helper.

## Behavioral Requirements

- **store-protocol**: A settings store MUST provide `setting(for:)` returning the raw `String?` stored under a key (nil when never set), `setSetting(_:_:)`, and `transaction(_:)`.
- **store-errors-propagate**: All three store requirements `throws`, and `WorkTrackingPrefs` MUST let a thrown store error reach the caller of `load`, `save`, `lastAccessibility`, `setLastAccessibility` and `trustedAccessibility`; it MUST NOT catch it.
- **transaction-atomic**: `transaction` MUST run its body so that, per the protocol comment, every write lands or none does.
- **load-default**: `load` MUST return `WorkTrackingPreferences.default` (disabled, no added ids, no removed ids, 90 retention days) for every key never set.
- **load-enabled**: `load` MUST read `activity_enabled` with `RawSetting.bool`, falling back to the default `enabled` for an absent or unrecognized value.
- **load-retention**: `load` MUST read `activity_retention_days` with `RawSetting.int`, falling back to 90 when the value is absent or not an integer and clamping into 7 through 3650.
- **load-ids**: `load` MUST read `activity_added_bundle_ids` and `activity_removed_bundle_ids` as a JSON array of strings, and MUST treat an absent, empty or undecodable value as no ids.
- **load-normalized**: `load` MUST return its result after `normalized()`, so ids are sorted ascending and de-duplicated.
- **load-key-reads-separate**: NEEDS REVIEW: Not implemented in source. `load` reads four keys through four separate `setting(for:)` calls outside any `transaction`, so a `save` from another thread or process can land between the reads and `load` can return a mix of old and new values. `WorkTrackingSettingsStore` itself is not `Sendable`, but the host store `WorkTrackingController` passes in conforms through `WorkTrackingPersistence` to `ActivityPersistence`, which is `AnyObject, Sendable`, so one store instance can be shared; the source states no ordering rule. A statement from the host on whether its store serializes reads against `save`, or a test that interleaves them, would settle it.
- **save-normalizes**: `save` MUST normalize the preferences before writing, so what is stored is already sorted, de-duplicated and clamped.
- **save-keys**: `save` MUST write all four keys: `activity_enabled`, `activity_added_bundle_ids`, `activity_removed_bundle_ids` and `activity_retention_days`.
- **save-enabled-text**: `save` MUST store `enabled` as the text `true` or `false`.
- **save-ids-json**: `save` MUST store each id list as a JSON array of strings, with `[]` when the encoded bytes cannot be read back as a string.
- **save-retention-text**: `save` MUST store the clamped retention as its decimal text.
- **save-one-transaction**: `save` MUST perform its four writes inside one `transaction`, so a failure leaves none of them.
- **save-encode-before-write**: `save` MUST encode both id lists before opening the transaction, so an encoding error is thrown with nothing written.
- **last-accessibility-read**: `lastAccessibility` MUST read `activity_ax_last_status` and return the `WorkTrackingAccessibility` whose raw value (`granted`, `denied` or `unknown`) matches it.
- **last-accessibility-default**: `lastAccessibility` MUST return `.unknown` when the key is absent or holds any other text.
- **set-last-accessibility**: `setLastAccessibility` MUST write the answer's raw value to `activity_ax_last_status` and the signer to `activity_ax_signer` inside one `transaction`.
- **nil-signer-stored-empty**: `setLastAccessibility` MUST store a nil signer as the empty string.
- **trusted-non-granted**: `trustedAccessibility` MUST return a stored `.denied` or `.unknown` unchanged for any signer, including nil, because trusting a denial never calls Accessibility.
- **trusted-granted-signature**: `trustedAccessibility` MUST return `.granted` only when the stored answer is `.granted`, the supplied signer is non-nil and non-empty, and it equals the signer stored under `activity_ax_signer`.
- **trusted-granted-otherwise-unknown**: `trustedAccessibility` MUST return `.unknown` for a stored `.granted` when the signer is nil, empty, differs from the recorded one, or no signer was recorded, so an unrecorded signature matches nothing.
- **raw-answer-kept**: `trustedAccessibility` MUST NOT change what `lastAccessibility` returns; the raw stored answer is kept.
- **no-validation-of-ids**: `save` and `load` MUST NOT check that an id looks like a bundle identifier; any string, including an empty one, is stored and returned (an empty string survives de-duplication as one entry).
- **no-logging-no-cache**: `WorkTrackingPrefs` MUST NOT cache or log; every call goes to the store.

## Appearance

Not applicable — this is a settings read and write helper, not a visual component.

## States

Not applicable — this is a settings read and write helper, not a visual component.

## Accessibility

Not applicable — this is a settings read and write helper, not a visual component. The code stores the answer of a macOS Accessibility permission check (`WorkTrackingAccessibility`); that is stored data, covered under Behavioral Requirements, not an accessibility feature of this code.

## Conformance Test Vectors

Derived from `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` and `testNormalizedSortsDedupsAndClamps` in `WorkTrackingModelsTests` (the latter exercises `normalized()`, which `load` and `save` rely on), `testUserSettingsSnapshotIsNormalized` in `WorkTrackingXPCClientTests`, `testLoadDefaultsWhenUnset` and `testSaveAndApplyNormalizeThePreferences` in `WorkTrackingControllerTests` (the only tests that call `load` and `save` directly, against the controller test's store), and the source.

| ID | Requirements | Input | Expected | Source |
|----|-------------|-------|----------|--------|
| work-tracking-prefs-001 | load-default | Empty store | `WorkTrackingPreferences(enabled: false, addedBundleIds: [], removedBundleIds: [], retentionDays: 90)` | `testLoadDefaultsWhenUnset` |
| work-tracking-prefs-002 | load-retention | `activity_retention_days` = `1` | `retentionDays` is 7 | source-derived |
| work-tracking-prefs-003 | load-retention | `activity_retention_days` = `99999` | `retentionDays` is 3650 | source-derived |
| work-tracking-prefs-004 | load-retention | `activity_retention_days` = `abc` | `retentionDays` is 90 | source-derived |
| work-tracking-prefs-005 | load-enabled | `activity_enabled` = ` YES ` | `enabled` is true | source-derived |
| work-tracking-prefs-006 | load-enabled | `activity_enabled` = `maybe` | `enabled` is false (the default) | source-derived |
| work-tracking-prefs-007 | load-ids, load-normalized | `activity_added_bundle_ids` = `["com.b","com.a","com.b"]` | `addedBundleIds` is `["com.a","com.b"]` | source-derived |
| work-tracking-prefs-008 | load-ids | `activity_added_bundle_ids` = `not json` | `addedBundleIds` is `[]`, no error | source-derived |
| work-tracking-prefs-009 | save-keys, save-enabled-text, save-ids-json, save-retention-text, save-normalizes | `save` of enabled true, added `["b","a","b"]`, removed `["z","z"]`, retention 1 | store holds `true`, `["a","b"]`, `["z"]`, `7` under the four keys | source-derived |
| work-tracking-prefs-010 | save-one-transaction | Store whose `setSetting` throws on the third write, transaction rolls back | `save` throws and no key changed | source-derived |
| work-tracking-prefs-011 | store-errors-propagate | Store whose `setting(for:)` throws | `load` throws the same error | source-derived |
| work-tracking-prefs-012 | trusted-granted-signature | `setLastAccessibility(.granted, signer: "A")` then `trustedAccessibility(signer: "A")` | `.granted` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-013 | trusted-granted-otherwise-unknown | Same store, signer `"B"`, then signer nil | `.unknown` both times | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-014 | raw-answer-kept | Same store | `lastAccessibility` is `.granted` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-015 | nil-signer-stored-empty, trusted-granted-otherwise-unknown | `setLastAccessibility(.granted, signer: nil)` then `trustedAccessibility(signer: "")` | `.unknown` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-016 | trusted-non-granted | `setLastAccessibility(.denied, signer: "A")` then `trustedAccessibility(signer: "B")` | `.denied` | `testAStoredGrantIsTrustedOnlyUnderItsOwnSignature` |
| work-tracking-prefs-017 | last-accessibility-default | Empty store; then `activity_ax_last_status` = `bogus` | `.unknown` both times | `testLoadDefaultsWhenUnset` for the empty store; source-derived for `bogus` |
| work-tracking-prefs-018 | save-ids-json | `save` with added `["", "", "x"]` | stored ids are `["", "x"]` | source-derived |
| work-tracking-prefs-019 | save-keys, save-normalizes, load-normalized | `save` of enabled true, added `["com.b","com.a","com.b"]`, removed `["z.y","a.b","z.y","a.b"]`, retention 1, then `load` | `load` returns added `["com.a","com.b"]`, removed `["a.b","z.y"]`, retention 7; the added key holds `["com.a","com.b"]` | `testSaveAndApplyNormalizeThePreferences` |
## Edge Cases

- **Unvalidated ids**: `save` and `load` do not check that an id looks like a bundle identifier; any string, including an empty one, is stored and returned, and an empty string survives de-duplication as one entry.
- **Never-set keys**: Each key a caller never wrote MUST read as its default (disabled, no ids, 90 days, `.unknown` accessibility); `setting(for:)` returning nil is not an error.
- **Hand-edited retention**: A value below 7 or above 3650 MUST be clamped on read and on write; an unparseable value MUST become 90.
- **Garbage id lists**: An absent, empty or non-array value (including an array of non-strings) MUST read as no ids; the source discards it without an error or a log line, and the doc comment on `decodeIds` declares that behavior.
- **Duplicate and unsorted ids**: Ids MUST come back sorted ascending by string order and unique, whatever order they were stored in.
- **Empty id list**: An empty list MUST be stored as `[]` and read back as no ids.
- **Store throws on read or write**: The error MUST reach the caller unchanged; a failed `save` MUST leave the four keys at their previous values when the store's `transaction` honors its atomic contract.
- **Missing signer record**: A `.granted` answer stored before signatures were recorded (no `activity_ax_signer` key) MUST read as `.unknown` through `trustedAccessibility`.
- **Concurrent access**: `WorkTrackingPrefs` holds no state and its functions are not isolated. `WorkTrackingSettingsStore` itself carries no `Sendable` requirement, but the host store reaches `ActivityPersistence`, which is `AnyObject, Sendable`, so one instance can be shared; the source states no ordering rule, so ordering of reads against `save` is the host's. Writes are atomic through `transaction`; reads are not grouped (see the open question on `load-key-reads-separate`).
- **Cancellation, timeouts, offline**: Not applicable — every call is synchronous, and the code does no networking, so there is nothing to cancel or to time out.

## Configuration
### Parameters

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `some WorkTrackingSettingsStore` | required | Passed to every function; the host's settings database. |
| `signer` | `String?` | required argument | Passed to `setLastAccessibility` and `trustedAccessibility`; the caller reads it from `OwnCodeSignature.designatedRequirement()`. |

### Stored keys

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `activity_enabled` | text | `false` | Whether tracking is on. |
| `activity_added_bundle_ids` | JSON array of strings | `[]` | Bundle ids the user added to the tracked apps. |
| `activity_removed_bundle_ids` | JSON array of strings | `[]` | Bundle ids the user removed from the tracked apps. |
| `activity_retention_days` | integer text | `90` | Days of history kept; clamped to 7 through 3650. |
| `activity_ax_last_status` | text | `unknown` | Last Accessibility answer: `granted`, `denied` or `unknown`. |
| `activity_ax_signer` | text | `""` | The designated requirement the last answer was recorded under. |
## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings; it stores and returns machine values (`true`, `granted`, JSON).

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag; `activity_enabled` is a user preference the tracker obeys, not a flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: The bundle ids the user added or removed, the retention length, and the Accessibility answer with the app's code-signing designated requirement.
- **Storage**: The host's settings table, through the injected store; this code adds no other storage.
- **Transmission**: None by this code; values leave only through whatever the host does with its store.
- **Retention**: Values stay until overwritten; `activity_retention_days` is stored here but governs the activity history, which is enforced elsewhere.

## Logging

Not applicable: this code makes no log calls; a decode failure on an id list is dropped without a record, as the `decodeIds` comment declares.

## Platform Notes

- **SwiftUI**: Source platform, but there is no view here. The file is `WorkTrackingPrefs.swift` under `Core/WorkTracking`; the protocol and the enum are `public`, the id codec helpers `private`. A SwiftUI settings pane reads preferences through `WorkTrackingUserSettings`, not this enum.
- **Compose**: Wrap a `DataStore<Preferences>` or a Room table behind the same three-method store interface. `load` reads the four keys (use one `data.first()` snapshot so the reads are consistent, which the source does not guarantee). Store the id lists as JSON strings with kotlinx.serialization and run `save` in one `updateData` or `withTransaction`.
- **React/Web**: A module of async functions over an `IndexedDB` or `localStorage` store; use one IndexedDB transaction for `save` and for the two accessibility keys. `JSON.parse` in a try block gives the "garbage is no ids" rule. Sort with a plain code-unit comparison to match Swift string ordering for ASCII ids.
- **AppKit / UIKit**: Same Swift file; it imports only `Foundation`. The host conforms its SQLite database to `WorkTrackingSettingsStore`, mapping `transaction` to `BEGIN`/`COMMIT` with rollback on throw.
- **WinUI 3**: A static class over an interface `IWorkTrackingSettingsStore` with `string? GetSetting(string key)`, `void SetSetting(string key, string value)` and `T Transaction<T>(Func<T> body)`. Back it with SQLite (`Microsoft.Data.Sqlite`, a `SqliteTransaction` committed on success and disposed on throw) or `Windows.Storage.ApplicationData.Current.LocalSettings` (which has no transaction, so serialize with a lock). Parse ids with `System.Text.Json.JsonSerializer.Deserialize<string[]>` inside a try/catch returning an empty array, sort with `StringComparer.Ordinal`, and clamp with `Math.Clamp(value, 7, 3650)`. Bool text parsing needs a small helper matching `1`/`true`/`yes`/`on` case-insensitively, because `bool.Parse` accepts only `true` and `false`. Unlike Swift's synchronous throws, a WinUI store would usually be async (`Task<string?>`), so the load, save and trust functions become `async Task` methods.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/WorkTrackingPrefs.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Preferences are normalized on both read and write.
**Rationale**: The doc comment says a hand-edited row "still means the nearest valid value", and an older or foreign writer cannot push an out-of-range retention or an unsorted id list into the tracker.
**Approved**: pending

**Decision**: The four preference keys are written in one transaction, but `load` does not read them in one.
**Rationale**: The source wraps writes in `transaction` and reads with plain `setting(for:)` calls; the protocol offers no read transaction, so a consistent read is the store's business. The open question on `load-key-reads-separate` records this.
**Approved**: pending

**Decision**: An undecodable id list reads as empty, not as an error.
**Rationale**: The comment on `decodeIds` says "anything else (absent, empty, garbage) is no ids", so a corrupt row degrades to the default instead of blocking tracking. The cost is that a corrupt row looks the same as a user who never added any ids, because the source neither logs nor reports the failure.
**Approved**: pending

**Decision**: A stored `.granted` holds only under the signature recorded with it; a denial holds under any.
**Rationale**: The doc comment on `trustedAccessibility` explains that TCC keys a grant to the code's designated requirement, so a grant recorded by a differently signed build is not known to hold; trusting a denial never calls Accessibility, while trusting a grant wrongly could make the tracker issue an Accessibility call that stalls.
**Approved**: pending

**Decision**: The raw last answer and its trusted reading are separate functions.
**Rationale**: `lastAccessibility` returns what was stored and `trustedAccessibility` applies the signature rule, so the daemon can show history while acting only on trusted answers; the test asserts "the raw answer is kept".
**Approved**: pending

**Decision**: The settings store is a protocol the host conforms, not a concrete database.
**Rationale**: The doc comment ties it to `BillingPersistence`; this keeps the SDK tier free of any SQLite dependency, and tests use a dictionary-backed store.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

Separation of concerns passes: the enum owns only the mapping between preference values and settings rows, storage is the injected protocol, and text parsing and clamping are delegated to `RawSetting` and the model's `normalized()`. Unit coverage passes: `WorkTrackingPrefsConformanceTests` (Core tests, `WorkTracking/WorkTrackingPrefsConformanceTests.swift`) has one test for each of the 19 vectors, including the retention clamp on read, the bool and integer parsing fallbacks, the garbage id list, the atomic write with rollback and the signature-gated trust. Data integrity is partial: writes are atomic and normalized, but the four reads in `load` are not grouped, and an undecodable id list is silently reset to empty.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (WorkTrackingPrefsConformanceTests.swift, 19 of 19 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Restore requirements lost in the lint pass: no-validation-of-ids |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added a Source column to the test vectors and split vector 009 from the tested round trip, moved the id-validation rule to an Edge Case, split Configuration into Parameters and Stored keys, reconciled the concurrency edge case, noted the cost of silently resetting a corrupt id list, and dropped the opaque review citation and the iOS claim. |
