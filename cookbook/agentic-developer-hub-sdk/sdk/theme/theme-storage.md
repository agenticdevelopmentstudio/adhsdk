---
id: ""
title: "ThemeStorage"
type: ingredient
version: 1.0.0
status: review
language: en
created: ""
modified: ""
author: ""
copyright: ""
license: ""
summary: "Main-actor persistence seam for custom themes and the active theme id, with an external-change hook so a host's own settings system can drive repaint."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - storage
  - persistence
  - protocol
depends-on: []
related:
  - 932449c9-b57f-4e2c-992a-1e27584742b6
references: []
approved-by: ""
approved-date: ""
---

# ThemeStorage

## Overview

`ThemeStorage` is the protocol that says where custom themes are persisted. The theme model does not own a settings system: a host that already has one supplies a conformer instead of inheriting a location for preferences. The surface is deliberately exactly what `ThemeStore` touches, which is two persisted values and one change hook.

Built-in themes are never stored. `ThemeStore` concatenates them with `BuiltInThemes.all` at read time, so an empty storage still yields a full catalog. The protocol is main-actor isolated and class-bound. `ThemeManager` is the consumer of the hook, and `UserDefaultsThemeStorage` is the conformer the SDK ships for hosts with no settings system of their own. The protocol itself contains no logic; this recipe specifies the contract a conformer must meet. The theme value being stored is described in [adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.color-theme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6).

## Behavioral Requirements

### Protocol shape

- **main-actor-isolated**: `ThemeStorage` MUST be isolated to the main actor, so every read, write and hook invocation of a conformer happens on the main thread.
- **class-bound**: `ThemeStorage` MUST be class-bound, so a `ThemeStore` that holds its storage as an immutable reference can still write through it.
- **minimal-surface**: `ThemeStorage` MUST declare exactly three members: `customThemes`, `activeThemeID` and `onExternalChange`. The source states the surface is exactly what `ThemeStore` touches.

### customThemes

- **custom-themes-type**: `customThemes` MUST be a readable and writable array of `ColorTheme`.
- **custom-themes-order**: `customThemes` MUST hold the user's imported and custom themes in insertion order.
- **custom-themes-round-trip**: A value written to `customThemes` MUST be what a later read returns, including a read after a later launch.
- **custom-themes-excludes-built-ins**: `customThemes` MUST NOT be used to store built-in themes; `ThemeStore` appends `BuiltInThemes.all` at read time.
- **custom-themes-empty-default**: A conformer with nothing persisted MUST read `customThemes` as an empty array, so the catalog is the built-in themes alone.

### activeThemeID

- **active-id-type**: `activeThemeID` MUST be a readable and writable optional string holding a `ColorTheme.id`.
- **active-id-none**: `activeThemeID` MUST read `nil` when no theme has ever been chosen (a fresh install).
- **active-id-round-trip**: A value written to `activeThemeID`, including `nil`, MUST be what a later read returns, including a read after a later launch.
- **active-id-cleared-on-delete**: When `ThemeStore.delete(id:)` removes the theme whose id equals `activeThemeID`, the store MUST write `nil` to `activeThemeID`, so storage never keeps pointing at a theme that no longer exists.

### onExternalChange

- **external-hook-type**: `onExternalChange` MUST be a readable and writable optional closure taking no arguments and returning nothing.
- **external-hook-fires**: A conformer with a way to observe its backing setting MUST invoke `onExternalChange` when `customThemes` or `activeThemeID` changes through any route other than writing through this protocol (a settings panel bound to the underlying setting, a sync from another device).
- **external-hook-silent-on-own-write**: A conformer SHOULD NOT invoke `onExternalChange` for a write made through its own `customThemes` or `activeThemeID` setters, because the writer has already applied the change and a reload would repeat it.
- **external-hook-optional-observation**: A conformer with nothing to observe (an in-memory test double) MAY leave `onExternalChange` as a plain stored property that is never invoked.
- **external-hook-consumer**: `ThemeManager` MUST assign `onExternalChange` in its initializer to a closure that holds `self` weakly and calls `reload()`. Without it a theme chosen elsewhere persists but nothing repaints until relaunch.
- **external-hook-reentrancy-tolerated**: `ThemeManager.selectTheme(id:)` writes `activeThemeID` and also calls `reload()` itself, so `reload()` can run twice for one selection. `reload()` MUST return without posting when the resolved theme equals the current theme, which is how a conformer's occasional echo of its own write stays harmless.

### Ordering, concurrency and side effects

- **ordering-main-actor**: Reads, writes and hook calls are serialised by main-actor isolation; no ordering rule beyond that is declared, and none is needed for the protocol.
- **no-side-effects-declared**: The protocol declares no file, network, notification or logging side effect; those belong to a conformer.
- **no-errors-declared**: Neither property can throw and neither setter returns a status, so a conformer that cannot persist has no way to report it through this protocol.

### Shipped and test conformers

- **user-defaults-conformer**: `UserDefaultsThemeStorage` is the SDK's conformer. It MUST persist `customThemes` as JSON under the key `theme.custom_themes` and `activeThemeID` as a string under `theme.active_theme_id`, the same keys and encoding a host settings system uses, so a host that later swaps conformers finds the user's themes where it left them.
- **user-defaults-undecodable**: `UserDefaultsThemeStorage` MUST read an undecodable `customThemes` blob as an empty array and MUST NOT trap.
- **user-defaults-unencodable**: `UserDefaultsThemeStorage` MUST ignore a `customThemes` write whose value fails to encode, leaving the stored value unchanged.
- **user-defaults-self-write-detection**: `UserDefaultsThemeStorage` MUST decide whether a change is external by comparing the stored values with the values it last wrote or last saw, and MUST record the new value before writing it. A boolean "writing" flag is wrong because the change notification arrives on a later run-loop turn.
- **user-defaults-coalescing**: `UserDefaultsThemeStorage` MUST NOT invoke `onExternalChange` when a foreign write stores the value it already had, and MUST invoke it at most once per notification.
- **user-defaults-injectable-domain**: `UserDefaultsThemeStorage` MUST accept the `UserDefaults` instance to use, defaulting to `.standard`, so a host with an app group can pass its shared suite.
- **in-memory-double**: Tests use `InMemoryThemeStorage`, a conformer whose two properties are stored values and whose hook is never invoked.

## Appearance

Not applicable — this is a persistence protocol, not a visual component.

## States

Not applicable — this is a persistence protocol, not a visual component. The protocol has no runtime state machine; a conformer's two values are plain state, and `activeThemeID == nil` means "no theme chosen yet".

## Accessibility

Not applicable — this is a persistence protocol, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-storage-001 | custom-themes-empty-default, active-id-none | Test `a fresh domain reads as no themes and no selection`: `UserDefaultsThemeStorage` over an empty private suite | `customThemes` is empty; `activeThemeID` is nil |
| theme-storage-002 | custom-themes-round-trip, user-defaults-conformer | Test `customThemes round-trips through the defaults domain`: write one theme with id `custom.test`, then read through a second storage over the same suite | The second storage returns one theme with id `custom.test` and name `Test` |
| theme-storage-003 | active-id-round-trip | Test `activeThemeID round-trips, and nil clears it`: write the GitHub Light id, read from a second storage, write `nil`, read again | First read returns the GitHub Light id; second read returns nil |
| theme-storage-004 | external-hook-silent-on-own-write, user-defaults-self-write-detection | Test `the storage's own writes do not report as external changes`: set a hook counter, write both properties, wait 50 ms | Counter is 0 |
| theme-storage-005 | external-hook-fires, user-defaults-self-write-detection | Test `a write from outside the seam reports as an external change`: write `theme.active_theme_id` straight to the defaults domain, wait 50 ms | Counter is at least 1 and `activeThemeID` reads the written id |
| theme-storage-006 | user-defaults-undecodable | Test `a corrupt custom-themes payload reads as no themes rather than trapping`: store the bytes of `not json` under `theme.custom_themes` | `customThemes` is empty |
| theme-storage-007 | external-hook-consumer, external-hook-fires | Test `writing UserSettings.activeThemeID.value directly posts didChangeNotification and updates currentPalette` in `ExternalThemeChangeObservationTests`: a `ThemeManager` over `UserSettingsThemeStorage`, then a direct write of the Dracula id | `ThemeManager.didChangeNotification` fires and `currentTheme.id` is the Dracula id |
| theme-storage-008 | external-hook-fires, external-hook-consumer | Test `writing UserSettings.customThemes directly posts didChangeNotification when it redefines the active theme`: rewrite the active custom theme with a new name through the setting | The notification fires and `currentTheme.name` is `Nord Custom (edited)` |
| theme-storage-009 | external-hook-reentrancy-tolerated | Test `selectTheme(id:) posts didChangeNotification exactly once, not twice`: select the Dracula id, drain the main queue | Exactly one notification is counted |
| theme-storage-010 | active-id-cleared-on-delete | `InMemoryThemeStorage` with a custom theme as `activeThemeID`; `ThemeStore.delete(id:)` of that theme (derived from the `delete` source; no named test) | `customThemes` no longer contains it and `activeThemeID` is nil |
| theme-storage-011 | external-hook-optional-observation | `InMemoryThemeStorage` with a hook set, then both properties written | The hook is never invoked |

## Edge Cases

- **Nothing persisted**: a conformer MUST return an empty `customThemes` and a nil `activeThemeID`; `ThemeStore` still yields the built-in catalog.
- **`activeThemeID` naming an unknown theme**: the protocol does not validate the id. `ThemeManager.reload` resolves it through `ThemeStore` and falls back to `BuiltInThemes.solarizedDark` when no theme matches.
- **Undecodable stored themes**: `UserDefaultsThemeStorage` MUST read them as empty rather than throw, because failing a preference read would take the whole app down. The stored blob is left in place and is not repaired.
- **Unencodable themes on write**: `UserDefaultsThemeStorage` MUST drop the write silently. The failure is not signalled to the caller (see `no-errors-declared`), and the previous stored value remains.
- **Writing `nil` to `activeThemeID`**: a conformer MUST accept it. `UserDefaultsThemeStorage` passes the optional straight to `UserDefaults`, which removes the key.
- **Several writes then one notification**: `UserDefaultsThemeStorage` MUST compare final values against the last seen values and fire at most once.
- **Foreign write storing the existing value**: not a change; the hook MUST NOT fire.
- **Hook unset**: a conformer MUST tolerate `onExternalChange == nil` and simply skip the call.
- **Conformer deallocation**: `UserDefaultsThemeStorage` removes its notification observer in `deinit`, and its hook closure is invoked only while the object is alive.
- **Concurrent access**: serialised by main-actor isolation of the protocol; the one nonisolated member, the observer token in `UserDefaultsThemeStorage`, is written once in `init` and read once in `deinit`, so it cannot race.
- **Offline, timeout, cancellation**: not applicable; the protocol is synchronous and does no network I/O. A sync-backed conformer's connectivity is that conformer's concern, and it reports arrivals through `onExternalChange`.
- **Storage full or unwritable**: the protocol has no error channel, so such a failure is not reported to `ThemeStore`. A conformer decides whether to log or ignore it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| customThemes | [ColorTheme] | empty array | Imported and custom themes in insertion order; read and written by `ThemeStore` |
| activeThemeID | String? | nil | `ColorTheme.id` of the selected theme; nil on a fresh install |
| onExternalChange | (() -> Void)? | nil | Set by `ThemeManager`; invoked by a conformer on a change from outside the seam |
| defaults (`UserDefaultsThemeStorage.init`) | UserDefaults | `.standard` | Domain used by the shipped conformer; pass a shared suite for an app group |
| `UserDefaultsThemeStorage.Key.customThemes` | String | `theme.custom_themes` | Defaults key for the JSON-encoded theme array; changing it orphans saved themes silently |
| `UserDefaultsThemeStorage.Key.activeThemeID` | String | `theme.active_theme_id` | Defaults key for the active theme id |

## Deep Linking

Not applicable: `ThemeStorage` declares only two persisted values and a hook, with no URL, route or scheme handling in its source.

## Localization

Not applicable: `ThemeStorage` and its shipped conformer contain no user-facing strings.

## Accessibility Options

Not applicable: `ThemeStorage` is a persistence protocol and reads no system display options.

## Feature Flags

Not applicable: the source of `ThemeStorage` reads no feature flag.

## Analytics

Not applicable: the source of `ThemeStorage` and `UserDefaultsThemeStorage` emits no analytics event.

## Privacy

Not applicable: the protocol stores theme definitions and one theme id and collects nothing. `UserDefaultsThemeStorage` writes them to the local defaults domain in plain form and transmits nothing itself; a host conformer that syncs them across devices owns that transmission.

## Logging

Not applicable: neither `ThemeStorage` nor `UserDefaultsThemeStorage` makes a log call; an undecodable or unencodable theme payload is handled without logging.

## Platform Notes

- **SwiftUI**: Source platform. The protocol is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ThemeStorage.swift` and imports only Foundation. The shipped conformer is `UserDefaultsThemeStorage.swift` in the same folder. A SwiftUI host can back a conformer with `@AppStorage` or an `@Observable` settings object; since both are main-actor state, the protocol's `@MainActor` isolation fits them directly.
- **Compose**: Use a Kotlin interface with two mutable properties and a nullable callback, backed by Jetpack DataStore or SharedPreferences. DataStore is asynchronous, so keep an in-memory cache that the synchronous getters read and have the store collect the flow to invoke the callback on the main dispatcher. Serialise the theme list with kotlinx.serialization under the same two key names.
- **React/Web**: Use a TypeScript interface with `customThemes`, `activeThemeID` and an optional `onExternalChange`, backed by `localStorage` under the same two keys. The browser's `storage` event fires only for writes from other tabs, which maps onto the external-change hook and makes self-write detection unnecessary.
- **AppKit / UIKit**: Same Swift protocol. `UserDefaults` is the platform answer, and the `didChangeNotification` posts for the process's own writes as well as foreign ones, which is why the shipped conformer compares values instead of using a flag. On macOS the host conformer `UserSettingsThemeStorage` fills the same role over the app's settings system.
- **WinUI 3**: Define a C# interface `IThemeStorage` with `IReadOnlyList<ColorTheme>`-style settable `CustomThemes`, a nullable `string? ActiveThemeId` and an `Action? ExternalChanged`. Back it with `Windows.Storage.ApplicationData.Current.LocalSettings` (a composite value or a JSON string under `theme.custom_themes`, serialised with `System.Text.Json`) for a packaged app, or a JSON file in `LocalFolder` otherwise. `LocalSettings` raises no change event for the process's own writes, so wire `ExternalChanged` to roaming-settings `DataChanged` or a `FileSystemWatcher` and keep the last-seen JSON to ignore echoes. Call the setters and the hook on the UI thread through `DispatcherQueue.TryEnqueue`, matching the main-actor rule, and make the owning class implement `INotifyPropertyChanged` when it is bound to a settings page.

## Design Decisions

**Decision**: Make persistence a protocol supplied by the host rather than a fixed settings location.
**Rationale**: The source comment says the theme model owns the model but not a settings system; a host with one supplies it instead of inheriting an opinion about where preferences live. The surface is exactly what `ThemeStore` touches because a seam wider than its one implementation would be guesswork.
**Approved**: pending

**Decision**: Never store built-in themes.
**Rationale**: `ThemeStore` concatenates custom themes with `BuiltInThemes.all` at read time, so an empty storage still yields a full catalog and a built-in change ships without a migration.
**Approved**: pending

**Decision**: Detect external changes by comparing stored values with last-seen values, not with a "writing" flag, and record the value before the write.
**Rationale**: The source documents that `UserDefaults.didChangeNotification` is delivered on a later run-loop turn, so a flag raised around a synchronous write is already down and every write would report itself; recording after the write arrives too late when the notification is synchronous. Value comparison also handles coalesced writes and a foreign write that stores the same value.
**Approved**: pending

**Decision**: Make `onExternalChange` a settable property that a conformer may never invoke.
**Rationale**: The source comment lets an in-memory test double leave it as a plain stored property. `ThemeManager` always installs it so that a theme chosen from a settings panel or a sync repaints without relaunch. It is a SHOULD rather than a MUST that a conformer stays silent on its own writes, because `ThemeManager.reload` already tolerates a duplicate call.
**Approved**: pending

**Decision**: Read an undecodable theme blob as an empty list and drop an unencodable write, with no error and no log.
**Rationale**: The source comment reasons there is nothing useful to do with an incompatible blob and that throwing would take the app down over a preference; an empty catalog still yields every built-in theme. The cost is that a decode failure is invisible, which this recipe records as a fact.
**Approved**: pending

**Decision**: Use the same two keys and JSON encoding as the host settings system.
**Rationale**: The source says a host that later grows a settings system can swap conformers and find the user's themes where it left them; the keys are load-bearing, and changing either orphans saved themes silently.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

`ThemeStorage` is a Foundation-only protocol with no logic: persistence is a seam the host fills, the model is `ColorTheme`, and consumption is split between `ThemeStore` and `ThemeManager`, so separation of concerns passes. Unit-test coverage is partial because the protocol has no test of its own; its contract is exercised through `UserDefaultsThemeStorageTests`, `ExternalThemeChangeObservationTests` and the in-memory double, and the delete-clears-selection rule has no named test. Data integrity is partial because the round-trip rule is stated in doc comments but cannot be enforced by the type, and the protocol has no error channel for a failed write. Data minimization passes because only theme definitions and one id are stored.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | | | Initial creation |
