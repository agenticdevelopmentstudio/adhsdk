---
id: edd40452-1ef7-42ba-b3e9-066a5a2ca1f6
title: "UserDefaultsThemeStorage"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "ThemeStorage backed by UserDefaults: persists custom themes and the active theme id as JSON, and reports only foreign changes through onExternalChange."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - storage
  - persistence
  - logic
depends-on: []
related:
  - 932449c9-b57f-4e2c-992a-1e27584742b6
references: []
approved-by: ""
approved-date: ""
---

# UserDefaultsThemeStorage

## Overview

`UserDefaultsThemeStorage` is the `ThemeStorage` implementation for a host that has no settings system of its own. `ThemeStorage` is a `@MainActor`, class-bound protocol with three members: `customThemes` (an array of `ColorTheme`), `activeThemeID` (an optional `String`) and `onExternalChange` (an optional closure). This class keeps the first two in a `UserDefaults` domain and uses `UserDefaults.didChangeNotification` to fire the third when something other than this object moved them.

The source comment gives the reason it exists: a host with a settings system supplies its own `ThemeStorage` instead of inheriting a preference location, and plenty of hosts (a single-window utility, an iOS app whose only preference is the theme) have none, so the same short implementation lives here once. The keys and the JSON encoding match what the AgenticDeveloperHubSDK host writes through its own settings system, so a host that later swaps this class for its own conformer finds the saved themes where this class left them.

Built-in themes are never stored here; the `ThemeStorage` comment states that `ThemeStore` concatenates them at read time, so an empty storage still yields a full catalog. The model type it stores is described by the `ColorTheme` recipe.

## Behavioral Requirements

Type and isolation

- **protocol-conformance**: `UserDefaultsThemeStorage` MUST conform to `ThemeStorage`, exposing `customThemes`, `activeThemeID` and `onExternalChange` as read-write properties.
- **main-actor**: The type MUST be `@MainActor` and a `final class`, so every read, write and the `onExternalChange` callback run on the main actor.
- **no-sendable**: The type MUST NOT be shared across actors; it is main-actor state, is not explicitly declared `Sendable`, and main-actor isolation is what keeps it in its domain.

Storage keys

- **key-custom-themes**: The custom themes MUST be stored under the key `theme.custom_themes`, exposed as `UserDefaultsThemeStorage.Key.customThemes`.
- **key-active-theme-id**: The active theme id MUST be stored under the key `theme.active_theme_id`, exposed as `UserDefaultsThemeStorage.Key.activeThemeID`.
- **keys-load-bearing**: The two key strings MUST NOT change. The source comment states that changing either orphans already-saved themes silently, and that they match the keys the host writes through its own settings system.

Initialization

- **init-defaults-parameter**: `init(defaults:)` MUST accept the `UserDefaults` instance to persist into and MUST default it to `UserDefaults.standard`. The doc comment says a host with an app group passes its shared suite.
- **init-snapshot**: `init` MUST record the current stored custom-themes data and active theme id as the last-seen values before observing, so values already on disk at construction do not report as a change.
- **init-observer**: `init` MUST register one observer for `UserDefaults.didChangeNotification` scoped to the given `defaults` object and delivered on the main queue.
- **deinit-removes-observer**: `deinit` MUST remove that observer from the default notification center.

customThemes

- **themes-read-empty-when-absent**: Reading `customThemes` MUST return an empty array when no data is stored under `theme.custom_themes`.
- **themes-read-decode**: Reading `customThemes` MUST decode the stored data as a JSON array of `ColorTheme` with a default `JSONDecoder` and return it in stored order.
- **themes-read-corrupt**: Reading `customThemes` MUST return an empty array, not throw or trap, when the stored data does not decode, and MUST log the decode error at error level. The source comment states that a stored blob of an incompatible shape is treated as no themes because there is nothing useful to do with it and throwing would take the app down over a preference. The corrupt blob is left in place; nothing deletes or repairs it.
- **themes-write-encode**: Writing `customThemes` MUST encode the array as JSON with a default `JSONEncoder` and store the resulting `Data` under `theme.custom_themes`.
- **themes-write-records-first**: Writing `customThemes` MUST record the encoded data as the last-seen themes before it calls the `UserDefaults` write, never after. The source comment states `UserDefaults` can deliver its change notification synchronously when the post and the observer queue are both the main queue, so a record made afterwards would arrive too late and the object would hear its own write.
- **themes-write-empty**: Writing an empty array MUST store the JSON text `[]`, so the key is present afterwards; it does not remove the key.
- **encode-failure**: When encoding `customThemes` fails, the setter MUST log the error at error level and return without writing, so the previous stored value and last-seen record stay. The caller is not told; the setter is non-throwing.

activeThemeID

- **active-read**: Reading `activeThemeID` MUST return the string stored under `theme.active_theme_id`, or nil when none is stored (the `ThemeStorage` comment: nil means none has ever been chosen).
- **active-write**: Writing `activeThemeID` MUST store the value under `theme.active_theme_id`.
- **active-write-nil-clears**: Writing nil MUST clear the stored value, so a later read, including from a new instance over the same domain, returns nil. This is the behavior of `UserDefaults.set(nil, forKey:)`.
- **active-write-records-first**: Writing `activeThemeID` MUST record the new value as the last-seen active id before the `UserDefaults` write, for the same reason as `themes-write-records-first`.
- **active-no-validation**: The setter MUST NOT check that the id names an existing theme; it stores whatever string it is given. Resolving an unknown id is the caller's job.

External-change detection

- **external-compare-values**: The observer callback MUST compare the currently stored themes data and active id with the last-seen values, and MUST invoke `onExternalChange` only when either differs. The source comment rejects a boolean "I am writing" flag because the notification arrives on a later run loop turn, after such a flag has been cleared, so every write would report itself and `ThemeManager` would reload the theme it had just applied.
- **external-update-last-seen**: When a difference is found, the object MUST update both last-seen values to the current stored values before invoking `onExternalChange`, so one foreign write fires the callback once.
- **external-coalesce**: When several writes are followed by one notification, the object MUST fire at most once. The source comment says comparing values gets the coalesced case right.
- **external-same-value**: A foreign write that stores the value this object already had MUST NOT fire the callback; the source comment calls that "genuinely not a change".
- **external-own-writes-silent**: Writes made through this object's own setters MUST NOT fire `onExternalChange`.
- **external-nil-callback**: With `onExternalChange` nil, a detected foreign change MUST update the last-seen values and do nothing else.
- **external-main-actor**: The callback MUST run on the main actor. The observer is delivered on the main queue and enters the main actor with `MainActor.assumeIsolated`; the observer holds `self` weakly, so a notification arriving after the object is released does nothing.
- **external-read-through**: After a foreign write, the getters MUST return the foreign value, because they read `UserDefaults` on every access and keep no cache of the themes or the id.
- **notification-granularity**: The observer MUST react to every `UserDefaults.didChangeNotification` for its domain, including changes to unrelated keys, and rely on the value comparison to filter them; a change to an unrelated key therefore does not fire the callback.
- **multiple-instances**: Two instances over the same `UserDefaults` domain each treat the other's writes as external, because each keeps its own last-seen values.

Persistence and side effects

- **persistence-medium**: Everything is persisted through `UserDefaults` set and get calls; the class never calls `synchronize()`, never touches the file system directly and never uses the network. Durability and flush timing are whatever `UserDefaults` provides.
- **cloud-and-suite**: Changes arriving from a shared suite or an iCloud-backed sync reach this object only through `UserDefaults.didChangeNotification`; the class has no sync code of its own.
- **failure-logging**: The class MUST log through `Loggable` (its own `logger`) on exactly two paths, a decode failure on read and an encode failure on write; it logs nothing else.

Deinit isolation

- **observer-unsafe-field**: The `observer` field is `nonisolated(unsafe)`: it is assigned once in `init`, read once in `deinit` and never touched between, so the nonisolated `deinit` cannot race it. The source comment says `isolated deinit` would state this in the type system but needs macOS 15.4 or iOS 18.4.

## Appearance

Not applicable — this is a persistence adapter, not a visual component.

## States

Not applicable — this is a persistence adapter, not a visual component. The runtime state is two last-seen values (the themes data and the active id) that start as what the domain held at `init` and are updated by this object's own writes and by each detected foreign change; they are covered under Behavioral Requirements.

## Accessibility

Not applicable — this is a persistence adapter, not a visual component.

## Conformance Test Vectors

Vectors are derived from `UserDefaultsThemeStorageTests` (Swift Testing, `.serialized`, `@MainActor`), which builds a private `UserDefaults` suite per test so one test never sees another's themes, and from the documented behavior in the source. Tests that expect a notification wait 50 milliseconds so it can arrive.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| udts-001 | themes-read-empty-when-absent, active-read | `emptyDefaultsReadAsEmpty`: new storage over an empty suite | `customThemes` is empty; `activeThemeID` is nil |
| udts-002 | themes-write-encode, themes-read-decode, key-custom-themes | `customThemesRoundTrip`: set `customThemes` to one theme (id `custom.test`, name `Test`), then read through a second storage over the same suite | the second storage returns one theme with id `custom.test` and name `Test` |
| udts-003 | active-write, active-read, key-active-theme-id | `activeThemeIDRoundTrips`: set `activeThemeID` to the GitHub Light theme id, read through a second storage | returns that id |
| udts-004 | active-write-nil-clears | `activeThemeIDRoundTrips`: after udts-003 set `activeThemeID` to nil, read through a new storage | returns nil |
| udts-005 | external-own-writes-silent, themes-write-records-first, active-write-records-first | `ownWritesAreNotExternalChanges`: set a callback that counts, set `activeThemeID` then `customThemes`, wait 50 ms | the count is 0 |
| udts-006 | external-compare-values, external-read-through, key-active-theme-id | `foreignWritesReportAsExternalChanges`: set a counting callback, write the GitHub Light id straight into the suite under `Key.activeThemeID`, wait 50 ms | the count is at least 1 and `activeThemeID` returns the GitHub Light id |
| udts-007 | themes-read-corrupt | `undecodablePayloadReadsAsEmpty`: store `Data("not json".utf8)` under `Key.customThemes`, read through a new storage | `customThemes` is empty; no trap |
| udts-008 | key-custom-themes, key-active-theme-id, keys-load-bearing | read `Key.customThemes` and `Key.activeThemeID` | `theme.custom_themes` and `theme.active_theme_id` |
| udts-009 | themes-write-empty | set `customThemes` to an empty array, read the raw `Data` under `Key.customThemes` | the data is the text `[]` and `customThemes` reads empty |
| udts-010 | init-snapshot | seed the suite with an active id, build a storage, set a counting callback, wait 50 ms | the count is 0 |
| udts-011 | external-same-value | storage with active id A; write A straight into the suite again, wait 50 ms | the count is 0 |
| udts-012 | external-coalesce, external-update-last-seen | write two different themes payloads and two ids straight into the suite in one turn, wait 50 ms | the count is 1 |
| udts-013 | notification-granularity | write an unrelated key into the suite, wait 50 ms | the count is 0 |
| udts-014 | multiple-instances | two storages over one suite, each with a counting callback; set `activeThemeID` through the first | the first count is 0 and the second count is at least 1 |
| udts-015 | external-nil-callback | storage with a nil callback; write a foreign id into the suite | no crash; a later foreign write of a different value still reports once a callback is set |
| udts-016 | init-defaults-parameter | `UserDefaultsThemeStorage()` | persists into `UserDefaults.standard` |

Vectors udts-001 to udts-007 are the source's own tests. The rest are derived from the source and have no test beside them.

## Edge Cases

- **Empty or missing data**: a domain with neither key reads as no themes and a nil active id. MUST.
- **Empty array write**: writing `[]` stores the text `[]` and the key stays present. MUST.
- **Corrupt stored themes**: undecodable data reads as an empty array and is left in place; the next write of `customThemes` overwrites it. An empty catalog still yields every built-in theme. MUST.
- **Partially valid stored themes**: `ColorTheme`'s decoder defaults the optional fields (`isBuiltIn`, `isImported`, `attribution`, `roleOverrides`, `typography`, `terminal`, `project`) when absent but throws when a required field (`id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `selection`, `ansi`) is missing; this class treats any decode throw as no themes at all, so one element missing a required field hides every other stored theme. MUST (as the source behaves).
- **Encode failure**: the write is dropped and the error is logged; the stored catalog is unchanged.
- **Unknown or empty active id**: any string, including the empty string, is stored unchanged; the setter does not validate. MUST.
- **Clearing the active id**: writing nil removes the stored value, and the last-seen id becomes nil first, so the removal does not report as external. MUST.
- **Foreign write of the same value**: does not fire the callback. MUST.
- **Several writes, one notification**: fires at most once. MUST.
- **Unrelated key changes**: the notification arrives but the comparison finds no difference, so no callback. MUST.
- **Notification timing**: the source comments describe delivery both as "a later turn of the run loop" and as synchronous when post and observer queue are both main; the record-before-write ordering is what makes both safe. MUST.
- **Concurrent access**: the class is `@MainActor`, so its own reads, writes and callback are serialized on the main actor; the compiler enforces this. A write from another process or thread into the same domain is the foreign-change case. MUST.
- **Release during a pending notification**: the observer holds `self` weakly and `deinit` removes it; a notification queued before release finds no object and does nothing. MUST.
- **Two instances over one domain**: each reports the other's writes as external; see `multiple-instances`. SHOULD be avoided by hosts that hold one storage per domain, because the source gives no way to distinguish them.
- **Cancellation and timeouts**: not applicable; every operation is synchronous and bounded.
- **Offline or disconnected state**: not applicable; the class does no network access. An iCloud-backed sync that arrives later is just another foreign change.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `defaults` | `UserDefaults` | `UserDefaults.standard` | The domain to persist into; a host with an app group passes its shared suite |
| `Key.customThemes` | `String` constant | `theme.custom_themes` | Key holding the JSON-encoded array of custom themes |
| `Key.activeThemeID` | `String` constant | `theme.active_theme_id` | Key holding the active theme id string |
| `onExternalChange` | `(() -> Void)?` | nil | Set by the consumer (`ThemeManager`) to reload and repaint; invoked on the main actor |

The class reads no environment variables and no feature flags.

## Deep Linking

Not applicable: the class is a persistence adapter with no screens or URL routes.

## Localization

Not applicable: the source contains no user-facing strings; it stores and returns data and its failure paths produce no message.

## Accessibility Options

Not applicable: the class has no rendering code and does not respond to Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: the user's custom theme definitions (colors, names, typography) and the id of the selected theme; no personal identifiers.
- **Storage**: the `UserDefaults` domain given to `init`, which is the app's preferences property list when the standard defaults are used or the shared suite's list for an app group. The source applies no encryption and sets no protection level.
- **Transmission**: this class sends nothing. A host that uses an iCloud-backed or shared domain has `UserDefaults` carry the values; that is outside this code.
- **Retention**: until the host overwrites or removes the keys; the class has no expiry or cleanup.

## Logging

The class conforms to `Loggable`. It logs at error level when the stored catalog fails to decode (the read returns an empty array) and when a catalog fails to encode (the write is dropped). The error description is logged as public; it holds no user data beyond the theme shape.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/UserDefaultsThemeStorage.swift`, with its tests in `SDK/Tests/AgenticDeveloperHubSDKTests/Theme/UserDefaultsThemeStorageTests.swift`. It imports `Foundation` and `os` (for the `Logger` behind `Loggable`) and no AppKit or UIKit, so it compiles for macOS and iOS. A SwiftUI host constructs one instance, hands it to `ThemeStore` and `ThemeManager`, and relies on `onExternalChange` to refresh observable theme state; the file is not an `ObservableObject` itself. The `nonisolated(unsafe)` observer field exists because `isolated deinit` needs macOS 15.4 or iOS 18.4; a project with that deployment floor can use the isolated form instead.
- **Compose**: Use `SharedPreferences` (or Jetpack `DataStore`) with the same two key names and a JSON string for the themes (kotlinx.serialization), plus `SharedPreferences.OnSharedPreferenceChangeListener` or the `DataStore` flow for change detection. `SharedPreferences` fires its listener for the app's own writes too, so keep the same last-seen comparison rather than a writing flag; `SharedPreferences` also holds listeners weakly, so the adapter must keep a strong reference to the listener it registers. Run the callback on the main dispatcher.
- **React/Web**: Use `localStorage` with the same two keys and `JSON.stringify` and `JSON.parse` wrapped in try and catch (an undecodable value reads as an empty array). The `storage` event fires only in other tabs, never the writing one, so a web port gets "own writes are silent" for free and still needs the value comparison for repeated identical foreign writes. Writing nil maps to `removeItem`. In a private window or a sandbox `localStorage` can throw, which the Swift source has no analogue for, so catch it.
- **AppKit / UIKit**: The class uses no AppKit or UIKit type; it behaves the same on both. `UserDefaults.didChangeNotification` fires for changes by this process as well as arriving ones, which is why the value comparison exists; do not replace it with a flag, because delivery timing varies as the source comments describe. A macOS host using `NSUbiquitousKeyValueStore` instead would observe `NSUbiquitousKeyValueStore.didChangeExternallyNotification`, which fires only for remote changes.
- **WinUI 3**: Persist with `Windows.Storage.ApplicationData.Current.LocalSettings.Values` (an `ApplicationDataContainer`) for a packaged app, or a JSON file in `ApplicationData.Current.LocalFolder` read through `Windows.Storage.FileIO` for an unpackaged one. Store `theme.custom_themes` as a string serialized with `System.Text.Json` (`JsonSerializer.Serialize` of a `List<ColorTheme>`), and `theme.active_theme_id` as a string; removing the key replaces `UserDefaults.set(nil, ...)` (`Values.Remove`). Wrap `JsonSerializer.Deserialize` in try and catch `JsonException` and return an empty list to match the corrupt-data contract. `LocalSettings` has no change notification, so for foreign changes in an unpackaged app watch the file with `System.IO.FileSystemWatcher` and marshal to the UI thread with `DispatcherQueue.TryEnqueue`; keep the last-seen strings and compare before raising the event, because `FileSystemWatcher` raises several events per save and also reports the app's own writes. Expose the callback as an `Action` or an event; `INotifyPropertyChanged` is optional and only needed if a view binds to `ActiveThemeId` directly. Main-actor isolation maps to touching the properties only from the UI thread (`DispatcherQueue`), since .NET has no compiler-enforced equivalent. `UserDefaults` has no equivalent of the app-group suite; an unpackaged shared location needs an explicit shared folder.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/UserDefaultsThemeStorage.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: `UserDefaults` is the storage for a host with no settings system of its own.
**Rationale**: The source comment names it the platform's own answer for exactly this case (`native-controls`) and says it spares each such host from rewriting the same short adapter.
**Approved**: pending

**Decision**: The keys `theme.custom_themes` and `theme.active_theme_id` and the JSON encoding match the host's own settings system.
**Rationale**: A host that later swaps this class for its own conformer finds the user's themes where this class left them. The source comment warns that changing either key orphans saved themes silently rather than noisily.
**Approved**: pending

**Decision**: External changes are detected by comparing stored values with last-seen values, not by a writing flag.
**Rationale**: The source comment explains that `UserDefaults.didChangeNotification` arrives on a later run loop turn, after a flag set and cleared around a synchronous write is back down, so every write would report itself and `ThemeManager` would reload the theme it had just applied. Value comparison also handles coalesced notifications and a foreign write of an unchanged value.
**Approved**: pending

**Decision**: The last-seen value is recorded before the write, never after.
**Rationale**: The source comment states the notification can be delivered synchronously when the post and the observer queue are both main, so a record made afterwards would arrive too late and the object would hear its own write.
**Approved**: pending

**Decision**: An undecodable stored blob reads as no themes rather than throwing.
**Rationale**: The source comment states there is nothing useful to do with an incompatible blob and that throwing would take the app down over a preference; an empty catalog still yields every built-in theme. The cost is that the corruption is invisible and the blob stays until overwritten.
**Approved**: pending

**Decision**: An encode failure on write is dropped and logged.
**Rationale**: The setter is non-throwing because the `ThemeStorage` protocol is, so the only signal available is a log line; leaving the stored catalog untouched keeps the last good state.
**Approved**: pending

**Decision**: The `observer` field is `nonisolated(unsafe)`.
**Rationale**: The source comment says it is written once in `init` and read once in `deinit`, so the nonisolated `deinit` cannot race it; `isolated deinit` would express this safely but needs macOS 15.4 or iOS 18.4.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | privacy-and-data |

Separation of concerns passes because the class does only persistence and change detection behind the `ThemeStorage` seam; the model, the catalog and the repaint live elsewhere. Unit-test coverage is partial: the source has six tests for round trips, nil clearing, silent own writes, foreign-write reporting and corrupt data, but nothing asserts the literal key strings, the empty-array write, coalesced notifications, an unchanged foreign value or the encode-failure path. Explicit error handling is partial: a decode failure yields an empty value and an encode failure leaves storage unchanged, and both are logged, but neither is reported to the caller because the protocol has no error channel. Graceful degradation passes because corrupt stored data reads as an empty catalog and the app keeps every built-in theme. Secure data storage passes because the data is a theme definition and a theme id, not credentials or personal data, so plain `UserDefaults` is the right medium.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Theme storage now logs decode and encode failures; claims verified against source |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
