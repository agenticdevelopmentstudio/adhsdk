---
id: 359e0f48-d617-4872-8da9-b01d774368a7
title: "Pane State Settings Storage Provider"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A settings storage provider that keeps each setting as a JSON string in a pane's own state, so a pane's overrides travel and die with the pane."
platforms:
  - swift
  - macos
tags:
  - ui
  - pane
  - settings
  - storage
depends-on: []
related:
  - 6363b5ff-f511-4e21-9ba7-6850787dba62
  - 846ec786-5b96-4ee0-b7db-d6ae4bd6e333
  - 2b4d0f95-dbdf-48a9-8579-a3e5b7d488fe
references: []
approved-by: ""
approved-date: ""
---

# Pane State Settings Storage Provider

## Overview

This provider is the override layer for a layered settings store. It
implements the settings storage contract (get, set, remove, contains, keys
with a prefix, and a change publisher) on top of a pane's state store, which
holds one string per key. A pane that uses it keeps its own setting overrides
with the rest of its state, so they are saved, restored and deleted along with
the pane. See [adhsdk.ingredient.foundation.layered-settings-store](cookbook:846ec786-5b96-4ee0-b7db-d6ae4bd6e333)
for the store that layers it over a broader fallback and
[adhsdk.ingredient.foundation.settings-storage](cookbook:6363b5ff-f511-4e21-9ba7-6850787dba62)
for the contract it implements.

Each value is written as JSON inside a one-element array, because a bare
scalar is not a JSON document. Every value is stored under the key made of a
prefix (default `settings.`) and the setting's name. A second entry, the index
(prefix plus `__keys`), holds a JSON array of the names this provider has
written. The index exists because the pane state store can read and write a
key but cannot list its keys, so it is the only way to answer a prefix query
after a relaunch.

A stored string that no longer decodes as the requested type, such as an enum
that lost a case, reads as absent, so the layer above falls back to its own
value instead of failing.

## Behavioral Requirements

- **main-actor-confined**: The provider MUST be confined to the main actor; the default prefix and the index name constants MUST remain readable from any context.
- **default-prefix**: The default storage prefix MUST be `settings.`.
- **index-name**: The index MUST be stored under the key made of the prefix followed by `__keys`.
- **configurable-prefix**: The initializer MUST accept a store and an optional prefix, and every storage key MUST begin with that prefix.
- **storage-key**: A setting MUST be stored under the key made of the prefix followed by the setting's name.
- **value-encoding**: `set` MUST store the value as the JSON text of a one-element array holding the value.
- **get-returns-stored**: `get` MUST return the stored value when the stored text decodes as a one-element array of the requested type.
- **get-falls-back-to-default**: `get` MUST return the setting's default value when nothing is stored.
- **undecodable-reads-absent**: `get` MUST return the setting's default value, and `contains` MUST return false, when the stored text does not decode as an array of the requested type.
- **contains-by-decode**: `contains` MUST return true only when the stored text decodes as an array of the requested type.
- **get-uses-first-element**: When the stored array holds more than one element, `get` MUST return the first.
- **set-records-name**: `set` MUST add the setting's name to the index when the index does not already contain it.
- **set-index-unique**: `set` MUST NOT add a name to the index a second time.
- **set-publishes**: `set` MUST publish the setting's name on `changes` after storing it, every time it stores.
- **set-encode-failure**: When the value cannot be encoded as JSON text, `set` MUST store nothing, MUST NOT publish, and MUST trip an assertion failure (active in debug builds only).
- **remove-deletes-value**: `remove` MUST delete the stored value for the setting.
- **remove-clears-index-name**: `remove` MUST take the setting's name out of the index.
- **remove-empties-index**: When the index becomes empty, the provider MUST delete the index entry instead of storing an empty array.
- **remove-publishes-when-present**: `remove` MUST publish the setting's name on `changes` only when a value, even a malformed one, was stored under the key.
- **remove-silent-when-absent**: `remove` MUST NOT publish when nothing was stored under the key.
- **keys-with-prefix**: `keys(withPrefix:)` MUST return the indexed names that start with the given prefix and still hold a stored value that is a one-element JSON array.
- **keys-sorted**: `keys(withPrefix:)` MUST return names in ascending string order.
- **keys-skip-malformed**: `keys(withPrefix:)` MUST leave out a name whose stored text is not a JSON array of exactly one element.
- **keys-skip-unindexed**: `keys(withPrefix:)` MUST NOT return a name that is not in the index.
- **index-survives-relaunch**: A provider built over a store that already holds an index MUST find, list and clear the names written by an earlier provider.
- **corrupt-index-reads-empty**: When the index text is missing or is not a JSON array of strings, the provider MUST treat the index as empty.
- **no-change-on-fallback**: The provider MUST NOT publish for a setting it was not asked to set or remove.

## Appearance

Not applicable: the provider is a non-visual storage object; the source draws nothing and holds no view.

## States

| State | Appearance change |
|-------|------------------|
| Default (nothing stored) | `get` returns the setting's default; `contains` is false; the index entry does not exist |
| Stored | The value is a one-element JSON array under the prefixed key; the name is in the index; `contains` is true and `get` returns the stored value |
| Malformed stored text | `get` returns the default and `contains` is false; `keys(withPrefix:)` leaves the name out; the text stays in the store until `set` or `remove` replaces it |
| Pressed | Not applicable: the provider has no pointer interaction |
| Disabled | Not applicable: the provider has no enabled or disabled state in source |
| Focused | Not applicable: the provider is not a focusable control |
| Loading | Not applicable: every read and write is synchronous against the store |

## Accessibility

Not applicable: the provider is a non-visual storage object with no control, label or focus behavior; it exposes no user interface of its own.

## Conformance Test Vectors

Derived from `PaneStateSettingsStorageProviderTests`, which sits beside the
source in the macOS test target. Vectors use an ephemeral in-memory pane state
store and the browser settings keys `browser.page_zoom` (Double, default 1.0),
`browser.home_page` (String), `browser.javascript_enabled` (Bool),
`browser.autoplay` (enum) and `browser.minimum_font_size` (Int).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-state-settings-001 | value-encoding, get-returns-stored, contains-by-decode, remove-deletes-value, get-falls-back-to-default (testRoundTripsBoolIntDoubleStringAndEnum) | Set false, 14, 1.25, "example.com" and the autoplay value never; read each back; then remove autoplay | Each read returns what was set; `contains` for autoplay is true, then false after `remove`, and `get` returns autoplay's default |
| pane-state-settings-002 | storage-key, default-prefix (testStoresUnderThePrefix) | Set 1.25 for `browser.page_zoom` | The store holds a non-nil value under `settings.browser.page_zoom` |
| pane-state-settings-003 | undecodable-reads-absent, contains-by-decode (testUndecodableOverrideFallsBack) | Store the text `not json` under `settings.browser.page_zoom` | `contains` is false and `get` returns 1.0 |
| pane-state-settings-004 | undecodable-reads-absent, no-change-on-fallback (testUndecodableOverrideFallsBack) | Same corrupt entry; a layered store over this provider with a fallback holding 1.5 | The layered `get` returns 1.5 and the layered store reports no override |
| pane-state-settings-005 | index-survives-relaunch, set-records-name, remove-clears-index-name (testOverridesFromAnEarlierProviderCanBeRemovedAfterARelaunch) | One provider sets zoom and home page; a second provider over the same store sits under a layered store; remove all overrides with prefix `browser.` | Before: the layered store reports a zoom override. After: neither override remains and the layered reads return the fallback values 1.5 and `global.com` |
| pane-state-settings-006 | undecodable-reads-absent, no-change-on-fallback (testACorruptOverrideStillReceivesTheGlobalChange) | Corrupt zoom entry; layered store over it; the fallback sets 1.5 | The layered `changes` publisher emits `browser.page_zoom` once and the layered `get` returns 1.5 |
| pane-state-settings-007 | keys-with-prefix, keys-sorted (testKeysWithPrefixListsOnlyWellFormedStoredNames) | Set zoom, home page and JavaScript flag; query prefixes `browser.`, `browser.p` and `editor.` | The lists are `browser.home_page`, `browser.javascript_enabled`, `browser.page_zoom`; then `browser.page_zoom`; then empty |
| pane-state-settings-008 | keys-skip-malformed, remove-clears-index-name (testKeysWithPrefixListsOnlyWellFormedStoredNames) | After vector 007, overwrite the zoom entry with `not json` and remove home page | `keys(withPrefix: "browser.")` returns only `browser.javascript_enabled` |
| pane-state-settings-009 | remove-silent-when-absent, remove-publishes-when-present, set-publishes (testRemoveOnlyPublishesWhenSomethingWasStored) | Subscribe to `changes`; remove zoom; set zoom 1.25; remove zoom | Published names after the first remove: none; after all three calls: `browser.page_zoom` twice |
| pane-state-settings-010 | set-index-unique, remove-empties-index | Set zoom twice, then remove it, on a fresh store | After the two sets the index text holds the name once; after the remove the store holds no value under `settings.__keys` |
| pane-state-settings-011 | corrupt-index-reads-empty | Store `not json` under `settings.__keys`, then `keys(withPrefix: "")` | The result is empty |
| pane-state-settings-012 | configurable-prefix, index-name | Build a provider with prefix `pane.`; set zoom | The value sits under `pane.browser.page_zoom` and the index under `pane.__keys` |
| pane-state-settings-013 | get-uses-first-element | Store `[2.0, 3.0]` under `settings.browser.page_zoom` | `get` returns 2.0; `keys(withPrefix:)` leaves the name out whether or not it is indexed, because the array has two elements |
| pane-state-settings-014 | undecodable-reads-absent | Store `["x"]` under the zoom key (a one-element array of the wrong type) | `contains` and `get` treat it as absent for the Double zoom key |

## Edge Cases

- **Nothing stored** (MUST): `get` returns the default and `contains` is false; no index exists.
- **Stored text is not JSON** (MUST): Reads as absent for `get` and `contains`, and `keys(withPrefix:)` leaves it out; the layer above falls back.
- **Stored text is JSON but not a one-element array** (MUST): `keys(withPrefix:)` leaves the name out; a typed `get` of a one-element array of the wrong element type also reads as absent. The source comment names this the one place `contains` and `keys` can still differ: only a typed caller can tell the element type, so `keys` can list a name that `contains` rejects for a different type.
- **Stored array is empty** (MUST): `get` reads it as absent (the decoded array has no first element) and `contains` is false, while `keys(withPrefix:)` also leaves it out because it requires exactly one element.
- **Stored array has several elements** (MUST): `get` returns the first, while `keys` leaves the name out because it requires exactly one.
- **Empty prefix filter** (MUST): `keys(withPrefix: "")` returns every indexed name that still holds a well-formed value.
- **Prefix with no match** (MUST): returns an empty array.
- **Value that cannot be encoded** (MUST): `set` stores nothing, leaves the index and the existing value alone, publishes nothing, and trips an assertion failure that only fires in debug builds; a release build fails silently.
- **Index text corrupt when setting** (MUST): The index reads as empty, so `set` writes an index holding only the new name; names the corrupt index held are no longer listed by `keys(withPrefix:)`, though their values remain stored and readable by `get`.
- **Name stored outside this provider** (SHOULD NOT rely on): A value written to the store directly under a prefixed key is readable by `get` and `contains` but is not listed by `keys(withPrefix:)` until a `set` through the provider indexes it.
- **Setting named like the index** (MUST): The source does not guard against a setting whose name equals `__keys`; it would share its storage key with the index.
- **Remove with a malformed value** (MUST): The stored text counts as a value, so it is deleted and `changes` publishes the name.
- **Remove of an indexed name whose value was deleted elsewhere** (MUST): The name leaves the index, nothing is published.
- **Same value set twice** (MUST): Each `set` publishes; the source does not compare with the stored value.
- **Concurrent access** (MUST): The type is confined to the main actor, so reads and writes are serialized on the main thread; there is no cross-thread access to define.
- **Network or offline state**: Not applicable: the provider reads and writes only the injected pane state store and performs no network call.
- **Boundary values**: Not applicable: the provider imposes no length or range limit on a value; limits belong to the setting type and the store behind the pane state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | PaneStateStore | none (required) | The pane's key and string store the provider reads and writes |
| prefix | String | `settings.` | Where the pane's settings live among its state keys; also prefixes the index key |
| defaultPrefix | static String | `settings.` | The default prefix constant |
| indexName | static String | `__keys` | The key, after the prefix, of the list of names a pane overrides |

## Deep Linking

Not applicable: the provider is a storage object with no address or route in source.

## Localization

Not applicable: the provider holds no user-facing string; its only text is JSON and storage keys.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the provider performs no animation. |
| Increase Contrast | Not applicable: the provider draws nothing. |
| Differentiate Without Color | Not applicable: the provider draws nothing. |

## Feature Flags

Not applicable: the source reads no flag; the provider is active whenever a pane builds one.

## Analytics

Not applicable: the source emits no analytics event; its `changes` publisher is an in-process notification, not telemetry.

## Privacy

- **Data collected**: The setting values a caller chooses to store as pane overrides; the provider adds nothing of its own.
- **Storage**: In the pane's state store, as JSON text under prefixed keys. The default store for a pane without persistence forgets them when the pane goes away; a project window's store keeps them with the pane.
- **Transmission**: None; the provider performs no I/O beyond the injected store.
- **Retention**: As long as the pane's state is retained, unless `remove` clears the value.

## Logging

Not applicable: the source writes no log entry; the only diagnostic is a debug-build assertion failure when a value or the index cannot be encoded.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/Panes/PaneStateSettingsStorageProvider.swift`, a `@MainActor` final class that imports `Foundation`, `Combine` and the SDK core, and conforms to `SettingsStorageProvider`. `changes` is a `PassthroughSubject` erased to `AnyPublisher`, so a SwiftUI view model can `sink` it into `@Published` state. It is UI-framework-agnostic; the same class works behind any SwiftUI view.
- **Compose**: Back it with a `Map` of string to string held in the pane's `ViewModel` or a `DataStore` keyed per pane; encode values with `kotlinx.serialization` as a one-element `JsonArray`, and expose `changes` as a `SharedFlow` of names. Confine writes to the main dispatcher.
- **React/Web**: A small class over a `Map` or a storage adapter (`sessionStorage` per pane, or a pane record in IndexedDB) using `JSON.stringify` of a one-element array and `JSON.parse` in a try block that reads as absent on failure; keep an index array under the prefixed `__keys` entry; emit names through an `EventTarget` or RxJS `Subject`.
- **AppKit / UIKit**: Identical to the SwiftUI note; the source makes no use of `AppKit` types. Its consumer is the browser pane, which supplies a pane state store (the project database in a project window, an in-memory store elsewhere) and layers this provider over the app-wide settings.
- **WinUI 3**: Implement an `ISettingsStorageProvider` class over an `IPaneStateStore` interface with `string? GetPaneStateValue(string key)` and `void SetPaneStateValue(string? value, string key)`; back the pane store with a `Dictionary<string,string>` for an ephemeral pane or an `ApplicationDataContainer` (`ApplicationData.Current.LocalSettings.CreateContainer`, one container per pane) for a persistent one. Encode with `System.Text.Json.JsonSerializer.Serialize(new[] { value })` and decode with `JsonSerializer.Deserialize<T[]>` inside a `try`/`catch (JsonException)` that returns the default, matching the "undecodable reads absent" rule. Keep the index as a JSON `string[]` under `prefix + "__keys"`, delete the entry when empty, and publish names through a .NET `event Action<string>` or an `IObservable<string>`. Marshal to the UI thread with `DispatcherQueue.TryEnqueue` to match the main-actor rule, and call `Debug.Fail` where the source calls `assertionFailure`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/Panes/PaneStateSettingsStorageProvider.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Each value is stored as JSON inside a one-element array.
**Rationale**: A bare scalar such as `1.25` or `true` is not a JSON document that every decoder accepts; wrapping it in an array makes every value decodable the same way.
**Approved**: pending

**Decision**: A stored string that no longer decodes reads as absent rather than throwing.
**Rationale**: An enum can lose a case between releases; reading absent lets the layer above fall back to its own value instead of crashing the pane.
**Approved**: pending

**Decision**: A separate index entry lists the names the provider has written.
**Rationale**: The pane state store cannot enumerate its keys, so without the index `keys(withPrefix:)` and clearing a family of overrides would stop working after a relaunch; the relaunch test records this.
**Approved**: pending

**Decision**: `keys(withPrefix:)` filters by a shallow well-formedness check (a one-element JSON array), not by the element type.
**Rationale**: Only a typed caller knows the element type; the source comment records that `contains` and `keys` can still differ for a value of the wrong element type.
**Approved**: pending

**Decision**: `remove` publishes only when something was stored, while `set` always publishes.
**Rationale**: A remove of nothing changes no reader's answer; the test for publishing records the first remove as silent. A set is treated as a change without comparing to the old value.
**Approved**: pending

**Decision**: A corrupt or missing index reads as empty, and the next `set` rewrites it with only the new name.
**Rationale**: The source never raises on a bad index. The cost is that names the corrupt index held stop appearing in `keys(withPrefix:)` although their values remain; the source accepts this rather than scanning the store.
**Approved**: pending

**Decision**: Encoding failure trips `assertionFailure` and stores nothing.
**Rationale**: A value that cannot encode is a programming error found in debug builds; release builds skip the write silently so a bad value cannot corrupt stored state.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

The provider does one job: translate settings reads and writes into string
reads and writes on an injected pane state store, knowing nothing of SQLite or
the pane, so separation of concerns passes. A test file beside the source
covers round trips, the prefix, undecodable values, relaunch, key listing and
publish rules, so unit test coverage passes. Explicit error handling is
partial because an encoding failure is an assertion in debug builds and a
silent skip in release, and a bad index is silently read as empty. Data
integrity is partial for the same index reason: a corrupt index drops names
from `keys(withPrefix:)` while leaving their values. Undecodable values read
as absent so the layer above falls back, so graceful degradation passes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
