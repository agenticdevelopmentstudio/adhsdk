---
id: d15bba09-4574-4fd1-93a0-f7d2cccd04f2
title: "ThemeStore"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The theme catalog: built-ins plus persisted custom themes, with add, update, delete, duplicate, JSON and iTerm import, and JSON export."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - store
  - import
  - persistence
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# ThemeStore

## Overview

`ThemeStore` is the catalog of selectable themes. It concatenates the built-in themes (`BuiltInThemes.all`) with the user's custom themes, which it reads from and writes to an injected `ThemeStorage`. It also holds the mutators that create custom themes: add, update, delete, add-new, duplicate, and three import paths (`.itermcolors`, `ColorTheme` JSON, and a content-sniffing front door), plus `exportJSON`. The same file declares `ThemeImportError`, the user-facing errors the JSON import raises.

It is Foundation-only and `@MainActor`, with no AppKit and no settings system, so it ships on every platform and is tested against an in-memory storage. The store caches nothing: every read goes to storage. Palette parsing lives in `ITermColorsParser`, the theme value type in `ColorTheme`, and the active-theme selection in `ThemeManager`; this recipe covers only the catalog and its persistence calls.

## Behavioral Requirements

Public surface: `ThemeStore.init(storage:)`, `customThemes`, `allThemes`, `theme(withID:)`, `isBuiltIn(id:)`, `add(_:)`, `update(_:)`, `delete(id:)`, `addNewTheme(basedOn:name:)`, `duplicate(_:nameSuffix:)`, `importITermColors(contentsOf:)`, `importTheme(contentsOf:)`, `importJSON(contentsOf:)`, `importJSON(data:)`, `exportJSON(_:)`, and the error enum `ThemeImportError` (`LocalizedError`) with cases `invalidPalette(count:)` and `foregroundMatchesBackground`. The mutators that return a `ColorTheme` are `@discardableResult`.

- **main-actor-isolation**: `ThemeStore` MUST be isolated to the main actor, so every call is serialised on one actor.
- **storage-injected**: `ThemeStore` MUST receive its `ThemeStorage` through `init(storage:)` and MUST NOT create or choose a storage itself.
- **no-cache**: `ThemeStore` MUST NOT cache themes; each read of `customThemes`, `allThemes`, `theme(withID:)` or `isBuiltIn(id:)` MUST reflect what the storage holds at that moment, so a second store over the same storage sees every earlier write.
- **custom-themes-read**: `customThemes` MUST return `storage.customThemes` unchanged, in storage (insertion) order.
- **all-themes-order**: `allThemes` MUST return `BuiltInThemes.all` followed by `customThemes`, so an empty storage still yields the full built-in catalog.
- **lookup-by-id**: `theme(withID:)` MUST return the first theme in `allThemes` whose `id` matches, or `nil` when none does. Because built-ins come first, a built-in wins over a custom theme that shares its id.
- **is-built-in**: `isBuiltIn(id:)` MUST return `true` exactly when `BuiltInThemes.theme(withID:)` finds the id, and `false` for custom and unknown ids.
- **add-appends**: `add(_:)` MUST set `storage.customThemes` to the current custom themes followed by the given theme and MUST return that theme.
- **add-unvalidated**: `add(_:)` MUST NOT validate the theme: it checks neither the palette length, nor id collisions with built-ins or custom themes, nor name uniqueness. Validation lives in the import paths.
- **update-replaces-by-id**: `update(_:)` MUST replace the custom theme that has the same `id` in place, keeping its position, and write the list back to storage.
- **update-noop-unknown**: `update(_:)` MUST do nothing, and MUST NOT write to storage, when no custom theme has the given `id`; this includes every built-in id.
- **delete-removes-custom**: `delete(id:)` MUST remove every custom theme with the given `id` and write the filtered list to storage.
- **delete-clears-active-id**: `delete(id:)` MUST set `storage.activeThemeID` to `nil` when it equals the given `id`, so storage never keeps pointing at a removed theme.
- **delete-builtin-noop**: `delete(id:)` MUST be a no-op when `id` names no custom theme, built-ins included: it writes nothing and leaves `activeThemeID` alone even when that id is the active theme. Covered by `builtInsAreUndeletable` and `deletingActiveBuiltInKeepsIt`.
- **delete-skips-noop-write**: `delete(id:)` MUST NOT write storage when no custom theme matched, so an unknown or built-in id leaves `customThemes` and `activeThemeID` untouched.
- **add-new-seed**: `addNewTheme(basedOn:name:)` MUST copy the template, defaulting to `BuiltInThemes.solarizedDark`, so the new theme keeps the template's palette, typography and other fields.
- **add-new-identity**: `addNewTheme` MUST give the copy a fresh `UUID().uuidString` id, set `isBuiltIn` and `isImported` to `false`, set `attribution` to `nil`, and store it through `add(_:)`.
- **add-new-name**: `addNewTheme` MUST name the copy `uniqueName(name)`, with `name` defaulting to `"New Theme"`.
- **unique-name**: The private `uniqueName(_:)` MUST return `base` when no theme in `allThemes` (built-in or custom) has that name; otherwise it MUST return `base` followed by a space and the smallest integer 2 or greater that makes the name unused.
- **duplicate-copy**: `duplicate(_:nameSuffix:)` MUST copy any theme (built-in, imported or custom), give the copy a fresh `UUID().uuidString` id, and store it through `add(_:)`.
- **duplicate-name**: `duplicate` MUST name the copy `uniqueName(theme.name + nameSuffix)`, with `nameSuffix` defaulting to `" Copy"`.
- **duplicate-unlocks**: `duplicate` MUST set `isBuiltIn` and `isImported` to `false` on the copy, so a copy of a locked theme is editable.
- **duplicate-keeps-content**: `duplicate` MUST keep the source theme's palette, typography and `attribution` on the copy.
- **import-iterm-delegates**: `importITermColors(contentsOf:)` MUST parse the file with `ITermColorsParser.parse(contentsOf:)`, so the theme name is the file's base name and parser errors propagate to the caller.
- **import-iterm-locked**: `importITermColors` MUST set `isImported` to `true` on the parsed theme and store it through `add(_:)`, returning the stored theme.
- **import-iterm-name-not-uniquified**: `importITermColors` MUST NOT disambiguate the theme name, so an import can share a name with an existing theme.
- **import-theme-sniffs-content**: `importTheme(contentsOf:)` MUST read the file bytes and choose the importer by content, not extension: when the first byte that is not one of 0x20, 0x09, 0x0A or 0x0D is `{` (0x7B) it MUST import as JSON, and otherwise it MUST import through `importITermColors(contentsOf:)`.
- **import-theme-read-error**: `importTheme` MUST propagate the error thrown when the file cannot be read, and MUST store nothing.
- **import-theme-fallthrough**: `importTheme` MUST send an empty or all-whitespace file to the `.itermcolors` path, where the parser's error surfaces.
- **import-json-url**: `importJSON(contentsOf:)` MUST read the file with `Data(contentsOf:)` and delegate to `importJSON(data:)`, propagating the read error.
- **import-json-decode**: `importJSON(data:)` MUST decode the bytes as a `ColorTheme` with `JSONDecoder`, and MUST propagate the decoding error unchanged when the JSON is malformed or incomplete.
- **import-json-palette**: `importJSON(data:)` MUST throw `ThemeImportError.invalidPalette(count:)` carrying the decoded `ansi.count` when the decoded theme does not have exactly `ColorTheme.ansiColorCount` (16) ANSI colors.
- **import-json-visible-text**: `importJSON(data:)` MUST throw `ThemeImportError.foregroundMatchesBackground` when the decoded `foreground` equals the decoded `background`.
- **import-json-check-order**: `importJSON(data:)` MUST check the palette length before the foreground and background comparison, so a theme failing both reports `invalidPalette`.
- **import-json-atomic**: `importJSON(data:)` MUST store nothing when any decode or validation step throws.
- **import-json-clamps-scale**: `importJSON(data:)` MUST clamp `typography.sizeScale` into `ThemeTypography.sizeScaleRange` (0.5 to 4) through `ThemeTypography.clampedSizeScale`, which maps a non-finite value (NaN or an infinity) to `1.0`, and MUST NOT reject the theme for a scale outside the range.
- **import-json-fresh-id**: `importJSON(data:)` MUST replace the file's `id` with a fresh `UUID().uuidString`, so an import cannot collide with or shadow a built-in or an existing custom theme.
- **import-json-flags**: `importJSON(data:)` MUST set `isBuiltIn` to `false` and `isImported` to `true`, whatever the file declares, so an import is locked, never permanent, and deletable.
- **import-json-stores**: `importJSON(data:)` MUST store the sanitised theme through `add(_:)` and return it, keeping the file's name and every other field unchanged.
- **export-json-format**: `exportJSON(_:)` MUST encode the given theme with `JSONEncoder` using `prettyPrinted` and `sortedKeys` output formatting and MUST return the bytes.
- **export-json-roundtrip**: The `exportJSON` output MUST be accepted by `importJSON(data:)` when the theme has 16 ANSI colors and distinct foreground and background; the exported `id` and lock flags are not preserved on import.
- **export-json-errors**: `exportJSON` MUST propagate any `JSONEncoder` error and MUST NOT touch storage.
- **import-error-text**: `ThemeImportError.errorDescription` MUST be `This theme has N ANSI colors; a valid theme needs exactly 16.` for `invalidPalette(count: N)` and `This theme's foreground and background are the same color, so its text would be invisible.` for `foregroundMatchesBackground`.
- **no-timeout-no-retry**: `ThemeStore` MUST NOT add a timeout, retry or cancellation to any call; every operation is synchronous and runs to completion on the main actor, including the file reads.
- **write-failure-silent**: `ThemeStore` MUST NOT report storage write failures, because the `ThemeStorage` setters are non-throwing and the store checks nothing after a write; durability belongs to the injected conformer (`UserDefaultsThemeStorage` for the default host).

Concurrency: the type is `@MainActor`, and every method is synchronous, so each read-modify-write (`add`, `update`, `delete`) runs without interleaving with another store call. A change made to the storage from outside the store (a settings panel, a sync from another device) can land between two calls; the store does not detect it, and the next call reads the new value. `ThemeStorage.onExternalChange` is how a host learns of that, and `ThemeStore` never sets or invokes it.

Persistence: nothing is persisted by the store itself. Custom themes and `activeThemeID` survive a restart only to the extent the injected `ThemeStorage` round-trips them, which the protocol requires of every conformer. Built-ins are never stored, and the ephemeral data is the store instance itself.

## Appearance

Not applicable — this is a theme catalog and persistence coordinator, not a visual component.

## States

Not applicable — this is a theme catalog and persistence coordinator, not a visual component. The store holds no runtime state machine; its only state is the injected `ThemeStorage`.

## Accessibility

Not applicable — this is a theme catalog and persistence coordinator, not a visual component.

## Conformance Test Vectors

Vectors are traced to `ThemeStoreTests` (suite `ThemeStore`) where a test exists; rows without a test name are derived from the source and unverified by a test.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-store-001 | no-cache, add-appends, lookup-by-id | `ThemeStoreTests.customThemeRoundTrips`: `add` a custom theme, then build a second `ThemeStore` over the same storage | The second store's `allThemes` contains the theme and `theme(withID:)` equals it |
| theme-store-002 | all-themes-order, custom-themes-read | `builtInsNeedNoStorage` and `startsWithBuiltIns`: a store over empty storage | `customThemes` is empty and `allThemes.count` equals `BuiltInThemes.all.count` |
| theme-store-003 | add-appends, is-built-in | `add` and `builtInDetection`: add one custom theme, then call `isBuiltIn` on `BuiltInThemes.defaultID` and the custom id | `customThemes.count` is 1, `allThemes.count` grows by 1, `isBuiltIn` is `true` for the default id and `false` for the custom id |
| theme-store-004 | update-replaces-by-id, update-noop-unknown | `update`: add a theme named Before, rename it to After and call `update`; then call `update` with Dracula renamed Hacked | The custom theme's name is After; Dracula's name stays Dracula |
| theme-store-005 | delete-removes-custom, delete-builtin-noop | `delete`: add a theme and delete its id; then delete `BuiltInThemes.defaultID` | The custom theme is gone; the built-in default is still found |
| theme-store-006 | delete-builtin-noop | `builtInsAreUndeletable`: delete the first built-in id | `allThemes` still contains it |
| theme-store-007 | delete-clears-active-id | Source-derived: storage with `activeThemeID` equal to a custom theme's id; call `delete(id:)` with that id | `storage.activeThemeID` is `nil` and the theme is gone |
| theme-store-008 | delete-builtin-noop | Source-derived: `activeThemeID` equals `BuiltInThemes.defaultID`; call `delete(id:)` with it | `allThemes` still holds the default; `activeThemeID` is unchanged (`deletingActiveBuiltInKeepsIt`) |
| theme-store-009 | delete-skips-noop-write | Source-derived: empty custom list; call `delete(id:)` with an unknown id | storage is not written and `activeThemeID` is unchanged |
| theme-store-010 | add-new-seed, add-new-identity, add-new-name | `addNew`: `addNewTheme(name: "Fresh")` | Name is Fresh, `isEditable` is `true`, `customThemes` contains it |
| theme-store-011 | unique-name, add-new-name | `addNewUniquifiesNames`: call `addNewTheme(name: "New Theme")` three times | Names are New Theme, New Theme 2, New Theme 3 |
| theme-store-012 | duplicate-copy, duplicate-name, duplicate-unlocks, duplicate-keeps-content | `duplicate`: `duplicate(BuiltInThemes.dracula)` | New id, `isBuiltIn` is `false`, name is Dracula Copy, `ansi` equals Dracula's, stored in `customThemes` |
| theme-store-013 | unique-name, duplicate-name | `duplicateUniquifiesNames`: add a theme named Base and duplicate it twice | Names are Base Copy and Base Copy 2 |
| theme-store-014 | duplicate-unlocks | `duplicateOfImportUnlocks`: export a sample, import it, duplicate the import | The copy has `isImported` and `isBuiltIn` both `false` and `isEditable` is `true` |
| theme-store-015 | duplicate-keeps-content | `duplicateKeepsAttribution` and `duplicatePreservesTypography`: duplicate a theme with attribution Somebody, `sizeScale` 1.4 and a Menlo body style | The copy has attribution Somebody and an equal `typography` |
| theme-store-016 | import-iterm-delegates, import-iterm-locked | `importITermColors` and `importITermMarksLocked`: write a valid XML plist named `Imported.itermcolors` and import it | Name is Imported, `isImported`, `isLocked` and `isDeletable` are `true`, and the theme is found by id |
| theme-store-017 | import-theme-sniffs-content | `importThemeSniffsContent`: ColorTheme JSON saved with a `.itermcolors` extension | `importTheme` imports it as JSON: name Mislabeled, `isImported` is `true` |
| theme-store-018 | import-theme-sniffs-content, import-theme-fallthrough | Source-derived: a JSON file with leading spaces, tab and newlines before `{`; and an empty file | The first imports as JSON; the empty file goes to the iTerm path and throws the parser's error with nothing stored |
| theme-store-019 | import-theme-read-error | Source-derived: `importTheme` on a URL that does not exist | The `Data(contentsOf:)` error is thrown and `customThemes` is unchanged |
| theme-store-020 | import-json-fresh-id, import-json-flags, import-json-stores | `jsonRoundTripLocks`: `exportJSON` then `importJSON(data:)` | New id differs from the source, name is Shared, the import is locked and deletable, and it is found by id |
| theme-store-021 | import-json-flags | `importJSONSanitizesBuiltIn`: export a theme with `isBuiltIn` true and import it | `isBuiltIn` is `false`, `isImported` is `true`, `isDeletable` is `true` |
| theme-store-022 | import-json-palette, import-json-atomic, import-error-text | `importJSONRejectsShortPalette`: JSON with 3 ANSI colors | `ThemeImportError` is thrown, `customThemes` is empty, and the message reads `This theme has 3 ANSI colors; a valid theme needs exactly 16.` |
| theme-store-023 | import-json-visible-text, import-json-atomic, import-error-text | `importJSONRejectsInvisibleText`: 16 ANSI colors, foreground and background both `#000000ff` | `ThemeImportError` is thrown and `customThemes` is empty; the message names the same-color problem |
| theme-store-024 | import-json-decode, import-json-stores | `importJSONAcceptsValid`: well-formed 16-color JSON named Good | Returns a theme named Good with `hasValidPalette` and `isImported` true |
| theme-store-025 | import-json-decode, import-json-atomic | Source-derived: `importJSON(data:)` with the bytes of `not json` | A `DecodingError` propagates and nothing is stored |
| theme-store-026 | import-json-clamps-scale | Source-derived: valid JSON with `sizeScale` 0, then another with 9 | The stored `typography.sizeScale` is 0.5 and 4 respectively; both imports succeed (a non-finite scale would become 1.0) |
| theme-store-027 | import-json-check-order | Source-derived: JSON with 3 ANSI colors and equal foreground and background | `invalidPalette(count: 3)` is thrown, not `foregroundMatchesBackground` |
| theme-store-028 | import-json-url | Source-derived: write a valid ColorTheme JSON to a file and call `importJSON(contentsOf:)`; call it on a missing file | The first stores a locked import; the second throws the read error |
| theme-store-029 | export-json-format, export-json-roundtrip | Source-derived: `exportJSON` of a theme | The bytes are pretty-printed with keys in sorted order and decode back to an equal `ColorTheme` |
| theme-store-030 | lookup-by-id, add-unvalidated | Source-derived: `add` a theme carrying a built-in's id | `theme(withID:)` returns the built-in, and `customThemes` holds both entries without error |
| theme-store-031 | import-iterm-name-not-uniquified | Source-derived: import an `.itermcolors` file whose base name matches an existing theme | The stored name equals the existing name with no numeric suffix |
| theme-store-032 | storage-injected, main-actor-isolation, no-timeout-no-retry, write-failure-silent | `ThemeStoreTests` construction: `ThemeStore(storage: InMemoryThemeStorage())` on the main actor | Every call completes synchronously and no storage error is surfaced by the store |

## Edge Cases

- **Empty storage** (MUST): a fresh install has no custom themes; `allThemes` is the built-ins alone and `theme(withID:)` returns `nil` for an unknown id.
- **Unknown id on update** (MUST): `update(_:)` does nothing and does not write to storage.
- **Unknown id on delete** (MUST): `delete(id:)` returns without writing storage or touching `activeThemeID`.
- **Deleting the active custom theme** (MUST): `activeThemeID` becomes `nil`, so a later import that reuses the id cannot silently become active.
- **Deleting a built-in id** (MUST): the built-in stays in the catalog; `activeThemeID` is left alone even when it names that built-in.
- **Id collisions through `add`** (SHOULD NOT be relied on): `add` accepts a theme whose id matches a built-in or custom theme; the built-in then shadows it in `theme(withID:)`. The import paths avoid this by assigning fresh ids.
- **Name collisions** (MUST): `addNewTheme` and `duplicate` add a numeric suffix starting at 2; `add` and the import paths keep the name as given.
- **Malformed JSON, wrong shape, or missing fields** (MUST): the `JSONDecoder` error propagates and nothing is stored.
- **ANSI count other than 16** (MUST): rejected with `invalidPalette(count:)`, including 0 and more than 16.
- **Foreground equal to background** (MUST): rejected with `foregroundMatchesBackground`; the comparison is whole-color equality.
- **sizeScale outside 0.5 to 4** (MUST): repaired by clamping, not rejected; a scale of 0 becomes 0.5, and a non-finite scale becomes 1.0.
- **Mislabeled file** (MUST): the first non-whitespace byte decides the importer, so a JSON file named `.itermcolors` and a plist named `.json` both import.
- **Binary or XML plist, or any non-`{` content** (MUST): handed to `ITermColorsParser`, whose errors surface; the file is read a second time on that path.
- **Missing or unreadable file** (MUST): the `Data(contentsOf:)` or parser read error propagates.
- **Concurrent access**: calls are serialised by `@MainActor`; an external storage change between two calls is not detected (see Behavioral Requirements, Concurrency).
- **Storage failure**: not surfaced; the setters cannot throw, so a conformer that fails to persist loses the write silently from the store's point of view (`write-failure-silent`).
- **Offline or disconnected state**: not applicable — the store reads local files and an injected local storage and makes no network request.
- **Cancellation and timeout**: not applicable — every call is synchronous with no suspension point.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` | `any ThemeStorage` | none (required) | Injected in `init(storage:)`: persists `customThemes` and `activeThemeID` and offers `onExternalChange` |
| `addNewTheme(basedOn:)` | `ColorTheme` | `BuiltInThemes.solarizedDark` | Template copied for a new theme; the doc comment suggests callers pass the active theme |
| `addNewTheme(name:)` | `String` | `"New Theme"` | Base name, disambiguated against `allThemes` |
| `duplicate(nameSuffix:)` | `String` | `" Copy"` | Appended to the source name before disambiguation |
| `ThemeTypography.sizeScaleRange` | `ClosedRange<Double>` | `0.5...4` | Bound applied to an imported theme's `sizeScale` |
| `ColorTheme.ansiColorCount` | `Int` | `16` | Required ANSI palette length for JSON import |

## Deep Linking

Not applicable: `ThemeStore` is a catalog and storage coordinator and defines no URL scheme or route.

## Localization

`ThemeImportError` carries user-facing English text that is hardcoded in `errorDescription` and is not routed through a localization table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `This theme has N ANSI colors; a valid theme needs exactly 16.` | `invalidPalette(count:)`, where N is the decoded count and 16 is `ColorTheme.ansiColorCount` |
| none (hardcoded) | `This theme's foreground and background are the same color, so its text would be invisible.` | `foregroundMatchesBackground` |

The default names `"New Theme"` and `" Copy"` are also hardcoded English defaults that a caller can override through the `name` and `nameSuffix` parameters.

## Accessibility Options

Not applicable: `ThemeStore` has no visual output and reads no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: no flag is read anywhere in `ThemeStore.swift`.

## Analytics

Not applicable: `ThemeStore.swift` emits no analytics event.

## Privacy

- **Data collected**: None collected by the store. It handles theme definitions (names, colors, typography, optional attribution text) and reads user-chosen theme files.
- **Storage**: Entirely in the injected `ThemeStorage`; the store keeps no copy. `UserDefaultsThemeStorage` is the bundled conformer.
- **Transmission**: The store makes no network call; data leaves the device only if the host's storage syncs it.
- **Retention**: Custom themes stay until `delete(id:)` removes them; the store applies no expiry.

## Logging

Not applicable: `ThemeStore.swift` makes no log call; failures are thrown to the caller instead.

## Platform Notes

- **SwiftUI**: The source platform is Swift, in `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ThemeStore.swift`, with tests in `packages/apple/AgenticDeveloperHubSDK/SDK/Tests/AgenticDeveloperHubSDKTests/Theme/ThemeStoreTests.swift`. It uses Foundation only (`Data`, `URL`, `UUID`, `JSONDecoder`, `JSONEncoder`) and depends on `ThemeStorage.swift`, `ColorTheme.swift`, `BuiltInThemes.swift`, `ITermColorsParser.swift` and `ThemeTypography.swift`. It is not `Observable`, so a SwiftUI view must refresh through `ThemeManager` or the host's own invalidation after a mutator runs.
- **Compose**: Hold the catalog in a `ViewModel` and expose `StateFlow<List<ColorTheme>>`. Persist custom themes through DataStore with `kotlinx.serialization` JSON; model `ThemeStorage` as an interface so the store stays free of Android types. Run the mutators on `Dispatchers.Main` to match `@MainActor`, move the file reads off it, and model `ThemeImportError` as a sealed class. Content sniffing reads the first non-whitespace byte of a `ByteArray` the same way.
- **React/Web**: Implement the store as a class over a storage interface backed by `localStorage` or IndexedDB. Single-threaded JavaScript already serialises each mutator. Import from a `File` with `await file.text()` or `arrayBuffer()`, and sniff the first non-whitespace byte for `{` (0x7B). Use `crypto.randomUUID()` for ids and `JSON.stringify` with a recursive key sort for `sortedKeys` output. Return a result object or throw typed `Error` subclasses for the two import errors.
- **AppKit / UIKit**: The store is identical on macOS and iOS because it is Foundation-only. The macOS settings UI (`ThemeSettingsPanelViewController`, `ThemePickerView`) calls it from the main thread; the store never sets `ThemeStorage.onExternalChange`, which `ThemeManager` hooks to reload. A document picker or `NSOpenPanel` supplies the file URL for `importTheme(contentsOf:)`; sandboxed apps must hold security-scoped access around the call.
- **WinUI 3**: Port as a `ThemeStore` class taking an `IThemeStorage` (members `List<ColorTheme> CustomThemes`, `string? ActiveThemeId`, `Action? ExternalChange`), backed by `Windows.Storage.ApplicationData.Current.LocalSettings` or a JSON file in `LocalFolder`. Expose `IReadOnlyList<ColorTheme> AllThemes` computed on each read to keep the no-cache rule, or an `ObservableCollection<ColorTheme>` refreshed after each mutator so a `ListView` binds with `INotifyPropertyChanged`. Do the work on the UI thread through `DispatcherQueue` to match `@MainActor`; the read-modify-write methods stay synchronous. Replace `Data(contentsOf:)` with `File.ReadAllBytes` or `await FileIO.ReadBufferAsync(StorageFile)` from a `FileOpenPicker`, which makes the import methods `async Task<ColorTheme>`. Use `System.Text.Json` for `JsonSerializer.Deserialize<ColorTheme>`; set `WriteIndented = true` for pretty-printing, but note that `System.Text.Json` does not sort keys, so sorted output needs a custom ordering or a `JsonNode` pass. Use `Guid.NewGuid().ToString().ToUpperInvariant()` to match `UUID().uuidString`, clamp with `Math.Clamp(scale, 0.5, 4.0)`, and replace the two import errors with exception types that override `Message`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ThemeStore.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: The store caches nothing and reads the injected storage on every call.
**Rationale**: A change made to the storage elsewhere (a settings panel, a sync) is then visible to the next call without invalidation, and the test `customThemeRoundTrips` relies on a second store over the same storage seeing the first store's writes.
**Approved**: pending

**Decision**: `delete(id:)` clears `activeThemeID` when it equals the deleted id.
**Rationale**: The doc comment explains that a stale id can never be satisfied by `reload()` and would snap back to active if a later import reused it. The method returns early when no custom theme matched, so a built-in id (or an unknown one) never writes storage or clears the active id, keeping the "no-op for built-ins" promise.
**Approved**: pending

**Decision**: `importJSON(data:)` replaces the id, forces `isBuiltIn` off and `isImported` on, and validates the palette and foreground against background.
**Rationale**: The doc comment says a hand-edited or malicious file must not shadow a built-in, become un-deletable, or enter the catalog as an unusable theme; a short ANSI array traps consumers that index all 16 slots, and equal colors make every glyph invisible.
**Approved**: pending

**Decision**: An out-of-range `typography.sizeScale` is clamped to 0.5 to 4 instead of rejected.
**Rationale**: The doc comment says a bad scale leaves the theme usable but mis-sized, so it is repaired; the same `ThemeTypography.clampedSizeScale` bounds `SemanticPalette.scaled(by:)` so the two limits cannot drift.
**Approved**: pending

**Decision**: `importTheme(contentsOf:)` chooses the parser from the first non-whitespace byte, not the file extension.
**Rationale**: The doc comment states that a mis-named file still imports; a JSON theme starts with `{` and an `.itermcolors` plist starts with `<` or `b`. The plist path therefore reads the file twice, once to sniff and once in the parser.
**Approved**: pending

**Decision**: Imports are locked (`isImported`), duplicates are unlocked, and only `addNewTheme` and `duplicate` disambiguate names.
**Rationale**: Locked imports keep shared themes intact while duplication is the way to customise them; repeated add and duplicate actions would otherwise stack indistinguishable rows, per the `uniqueName` doc comment. Imports keep the file's own name.
**Approved**: pending

**Decision**: `add(_:)` and `update(_:)` do not validate the theme.
**Rationale**: The editor and the factory methods are the callers that build themes; validation sits at the import boundary where untrusted data enters. The source states no further reason.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | security |

The store does one job, cataloguing themes over an injected storage, and leaves palette parsing, the theme value, persistence and the active selection to `ITermColorsParser`, `ColorTheme`, `ThemeStorage` and `ThemeManager`, so separation of concerns passes. Unit-test coverage is partial: `ThemeStoreTests` covers add, update, delete, duplicate, add-new, both import routes, content sniffing, validation failures and name disambiguation, but has no test for `delete(id:)` clearing `activeThemeID`, the `sizeScale` clamp, `importJSON(contentsOf:)`, `exportJSON` formatting, a leading-whitespace JSON file, a plist routed through `importTheme`, or the empty-file and unreadable-file paths. Explicit error handling is partial: import and export failures are thrown typed or propagated, but storage writes cannot fail visibly and the active-id side effect of deleting a built-in conflicts with its doc comment. Input sanitization passes for the import boundary, which assigns a fresh id, forces the lock flags, validates the palette and clamps the scale, while the unvalidated `add(_:)` is a documented caller responsibility.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Non-finite size scale becomes 1.0; a delete that matches nothing skips the write; claims verified against source |
