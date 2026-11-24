---
id: 1a0b943c-35f4-4568-9d92-033acce97afb
title: "AI Config Push Ledger"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A per-host record of the provider configuration ids last pushed to the daemon, so a later push names exactly the ones it dropped and never deletes another host's."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - ai-provider
  - sync
depends-on: []
related:
  - b05ceb21-7c1c-4d62-83ba-01a3132df00a
  - 402e0ab0-6488-403b-bc43-fbc9145a9a27
references: []
approved-by: ""
approved-date: ""
---

# AI Config Push Ledger

## Overview

`AIConfigPushLedger` remembers which AI provider configuration ids one host has pushed to the daemon. A later push uses it to name exactly the configurations it dropped (`AIProviderConfigSync.removedConfigIds`), instead of asking the daemon to delete everything it was not sent.

Two hosts share one daemon registry: the Kitchen over HTTP and the Stenographer app over XPC. Each keeps its own ledger under its own `key`, so neither ever deletes a configuration it did not push itself. The ledger is a `Sendable` struct over `UserDefaults`, which stores the ids as a sorted array of UUID strings under the ledger's key.

## Behavioral Requirements

- **key-namespace**: Each ledger MUST read and write only the `UserDefaults` entry named by its `key`, so two ledgers with different keys never see each other's ids.
- **defaults-injection**: The initializer MUST take the `UserDefaults` store as a parameter defaulting to the standard store.
- **last-pushed-read**: `lastPushed()` MUST return the set of UUIDs stored under the key by the last recorded push.
- **last-pushed-empty**: `lastPushed()` MUST return an empty set when nothing is stored under the key.
- **last-pushed-skips-malformed**: `lastPushed()` MUST skip any stored string that is not a valid UUID and return the rest.
- **removed-difference**: `removed(configured:)` MUST return the ids in `lastPushed()` that are not in `configured`.
- **removed-order**: `removed(configured:)` MUST return its ids sorted ascending by their `uuidString`.
- **configured-means-held**: The `configured` argument is every configuration the host holds now, resolvable or not; a configuration that is configured but unresolvable this time MUST NOT be returned as removed.
- **first-push-removes-nothing**: With an empty ledger, `removed(configured:)` MUST return an empty array.
- **record-landed-union**: `recordLanded(_:)` MUST store the union of the ids in `sync.configs` and the previously pushed ids that the sync did not remove.
- **record-landed-removals**: `recordLanded(_:)` MUST drop every id listed in `sync.removedConfigIds` from the previously pushed ids; a nil `removedConfigIds` drops nothing.
- **record-landed-configs-win**: An id that appears in both `sync.configs` and `sync.removedConfigIds` MUST be stored, because `sync.configs` is always recorded.
- **record-landed-keeps-unresolved**: A previously pushed id that is absent from `sync.configs` and not in `removedConfigIds` MUST remain in the ledger.
- **record-landed-format**: `recordLanded(_:)` MUST store the ids as UUID strings sorted ascending, replacing the whole entry under the key.
- **record-only-landed**: The ledger MUST be updated only by an explicit `recordLanded(_:)` call; `removed(configured:)` and `lastPushed()` MUST NOT write.
- **caller-records-after-landing**: Callers MUST call `recordLanded(_:)` only for a push the daemon accepted; the type has no knowledge of delivery.
- **caller-serialises**: Callers MUST NOT call `recordLanded(_:)` concurrently on one key, because it reads then writes the entry with no lock.

## Appearance

Not applicable — this is a persisted id ledger, not a visual component.

## States

Not applicable — this is a persisted id ledger, not a visual component.

## Accessibility

Not applicable — this is a persisted id ledger, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-config-push-ledger-001 | first-push-removes-nothing, last-pushed-empty | Fresh ledger; `removed(configured: [UUID()])`. | `[]` (test: testFirstPushRemovesNothing). |
| ai-config-push-ledger-002 | record-landed-union, removed-difference | Record a sync whose configs are first and second with `removedConfigIds` empty; then `removed(configured: [first])`. | `[second]` (test: testARecordedPushThenADroppedConfigurationIsRemoved). |
| ai-config-push-ledger-003 | configured-means-held | After that record, `removed(configured: [first, second])`. | `[]` (test: testAConfiguredButUnresolvedConfigurationIsNeitherRemovedNorForgotten). |
| ai-config-push-ledger-004 | record-landed-keeps-unresolved | Record a sync of only first, with empty `removedConfigIds`, after second was recorded. | `lastPushed()` is first and second (test: testAConfiguredButUnresolvedConfigurationIsNeitherRemovedNorForgotten). |
| ai-config-push-ledger-005 | record-landed-removals | Record first and second; then record a sync of first with `removedConfigIds` of second. | `lastPushed()` is first only (test: testARemovalDropsTheIdFromTheLedger). |
| ai-config-push-ledger-006 | key-namespace | Record under key `http`; call `removed(configured: [])` on a ledger with key `xpc` over the same store. | `[]` (test: testTwoLedgersWithDifferentKeysAreIndependent). |
| ai-config-push-ledger-007 | last-pushed-skips-malformed | Store the strings `not-a-uuid` and a valid UUID under the key. | `lastPushed()` holds only the valid UUID (test: testV7_malformedStoredIdsAreSkipped). |
| ai-config-push-ledger-008 | removed-order | Ledger holds three ids; none configured. | The result is in ascending `uuidString` order (test: testV8_removedIdsComeBackInAscendingUUIDStringOrder). |
| ai-config-push-ledger-009 | record-landed-removals | Record a sync with nil `removedConfigIds` and one config over a ledger holding another id. | The other id stays in the ledger with the new one (test: testV9_aNilRemovalListKeepsTheExistingIdsBesideTheNewOne). |
| ai-config-push-ledger-010 | record-landed-format | Record two configs, then read the raw entry. | An array of two UUID strings sorted ascending (test: testV10_theStoredEntryIsASortedArrayOfUUIDStrings). |
| ai-config-push-ledger-011 | record-landed-configs-win | Record a sync whose `configs` holds first and whose `removedConfigIds` also names first. | `lastPushed()` holds first (test: testV11_aConfigThatIsAlsoListedAsRemovedStaysInTheLedger). |
## Edge Cases

- **Null / empty input**: An unset key, or an empty `configured` list over an empty ledger, yields empty results. A nil `removedConfigIds` removes nothing from the ledger.
- **Boundary values**: Not applicable: the ledger holds no numeric limits; its size is the number of configuration ids pushed.
- **Concurrent access**: `recordLanded(_:)` is a read-then-write over `UserDefaults` with no lock, so two concurrent records on one key could lose an update. The type is declared `Sendable` and `UserDefaults` is documented thread-safe, but that covers each call, not the pair. Callers serialise, and the one caller does so through a push engine with a single in-flight push (`SettingsSnapshotPush`).
- **Error states**: A stored value that is not an array of strings reads as empty. Malformed strings are skipped without a signal; the ledger throws and logs nothing. A failed write to `UserDefaults` cannot be observed. A corrupt or non-array entry therefore reads as an empty ledger: the next push names no removals, so configurations it dropped stay behind in the daemon, and the next `recordLanded(_:)` rewrites the entry without the malformed ids.
- **Offline / disconnected state**: Not applicable: the ledger touches only local `UserDefaults`. A push that did not land is simply never recorded, so its ids stay out of the ledger.
- **Caller facts**: The one caller in source records only when its send reports the push landed, and sends through a push engine that holds one push in flight at a time.
- **Id in both lists**: An id in both `sync.configs` and `sync.removedConfigIds` stays in the ledger (see `record-landed-configs-win`).
- **Unresolvable configuration**: A configuration still held but not resolved is neither removed nor forgotten: it stays in the ledger and is not listed as removed.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| key | `String` | none, required | The `UserDefaults` key that holds this host's last-pushed ids; each host uses its own (the HTTP push in `StenographerAIConfigPush` uses `stenographer.aiConfigPush.http.lastPushedIds`). |
| defaults | `UserDefaults` | `.standard` | The store the ledger reads and writes; injectable for tests. |

## Deep Linking

Not applicable: the type defines no URL scheme or route.

## Localization

Not applicable: the type contains no user-facing string.

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Configuration ids only (random UUIDs); no name, value or secret is stored.
- **Storage**: `UserDefaults`, in plain text, under the ledger key.
- **Transmission**: None; the ledger sends nothing.
- **Retention**: An id stays until a recorded push lists it in `removedConfigIds`; nothing expires it.

## Logging

Not applicable: the type calls no logging API; a malformed stored id is skipped silently.

## Platform Notes

- **SwiftUI**: No SwiftUI-specific guidance: the type has no UI.
- **Source**: `Core/Stenographer/AIConfigPushLedger.swift`, importing only `Foundation`. A `Sendable` struct holding a `nonisolated(unsafe)` `UserDefaults` (marked unsafe because the SDK has not marked it `Sendable`). It reads with `stringArray(forKey:)` and `compactMap(UUID.init(uuidString:))`, and writes `map(\.uuidString).sorted()` with `set(_:forKey:)`. It depends on `AIProviderConfigSync` for `recordLanded`.
- **Compose**: Use `SharedPreferences` or Jetpack DataStore holding a sorted JSON array string under the key (a `SharedPreferences` string set is unordered, which would break `record-landed-format`), and `java.util.UUID.fromString` guarded by try/catch to skip malformed entries. A read-modify-write needs `edit()` and a single writer, or DataStore's `updateData`.
- **React/Web**: Use `localStorage` with a JSON array of strings under the key, filtering entries that fail a UUID regular expression, and a `Set` for the difference. Browser storage is per origin and synchronous, so the read-write pair cannot interleave within one tab; `localStorage` is shared across tabs, so multiple tabs need a cross-tab lock (the Web Locks API) or a single writer.
- **AppKit / UIKit**: The source description above applies as is: it uses `UserDefaults` and has no UI.
- **WinUI 3**: Use `Windows.Storage.ApplicationData.Current.LocalSettings.Values[key]` holding a JSON-serialised string array via `System.Text.Json`, or a file in `LocalFolder`. Parse with `Guid.TryParse` to skip malformed entries, use `HashSet<Guid>` and `SortedSet`, and order by `Guid.ToString("D").ToUpperInvariant()` with `StringComparer.Ordinal`, so the stored order matches Swift's ascending `uuidString` order (Swift's `uuidString` is uppercase). Guard the read-modify-write with a `SemaphoreSlim` if callers could overlap.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/AIConfigPushLedger.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Each host keeps its own ledger under its own key.
**Rationale**: The source comment explains that two hosts share one daemon registry; a per-host record is what lets each delete only what it pushed.
**Approved**: pending

**Decision**: A push names removed ids explicitly instead of asking the daemon to delete everything it was not sent.
**Rationale**: When `removedConfigIds` is non-nil the daemon treats the sync as partial and deletes exactly those ids; a nil value makes it delete every stored configuration not listed, which would erase another host's.
**Approved**: pending

**Decision**: `removed(configured:)` takes every configuration the host holds, resolvable or not.
**Rationale**: A configuration that could not be resolved this time is absent from `configs` but still configured; counting it as held keeps it from being deleted from the daemon.
**Approved**: pending

**Decision**: The ledger is updated only after a push lands.
**Rationale**: A failed push must leave the ledger as it was so the removal is named again on the next push.
**Approved**: pending

**Decision**: Ids are stored sorted.
**Rationale**: A stable stored order makes the entry deterministic; the source does not state a further reason.
**Approved**: pending

**Decision**: A corrupt or non-array ledger entry reads as an empty ledger, silently.
**Rationale**: `lastPushed()` has no failure channel and uses `stringArray(forKey:)` with `compactMap`, so the ledger neither throws nor logs; the cost is that the next push names no removals for configurations the ledger no longer remembers.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |

`separation-of-concerns` passes because the type only records and diffs ids; sending the push and deciding when it landed stay with the host. `unit-test-coverage` passes: `AIConfigPushLedgerTests` (`AIConfigPushLedgerTests.swift`) covers the first push, a dropped configuration, an unresolved configuration, a removal, key independence, malformed-id skipping, ordering, the stored format, a nil `removedConfigIds` and configs winning over removals. `AIConfigPushLedgerTests` covers the first push, a dropped configuration, an unresolved configuration, a removal and key independence; malformed-id skipping, ordering, the stored format and a nil `removedConfigIds` have no test. `idempotent-operations` passes because recording the same landed sync twice leaves the same stored set.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (AIConfigPushLedgerTests.swift, 11 of 11 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Downgraded unit-test-coverage to partial, specified that an id in both configs and removedConfigIds is kept, recorded the corrupt-entry consequence as an edge case and Design Decision, moved caller facts out of MUSTs, and fixed the WinUI, Compose, Web and SwiftUI platform notes. |
