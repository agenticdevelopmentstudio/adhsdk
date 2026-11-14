---
id: 932449c9-b57f-4e2c-992a-1e27584742b6
title: ColorTheme
type: ingredient
version: 1.0.0
status: review
language: en
created: '2026-11-14'
modified: '2026-11-14'
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: 'The app-wide color theme value type: terminal palette, identity and lock
  flags, semantic role overrides, typography and per-feature options, with tolerant
  Codable decoding.'
platforms:
- swift
- macos
- ios
tags:
- theme
- color
- model
- codable
depends-on: []
related:
- 0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6
references: []
approved-by: ''
approved-date: ''
---

# ColorTheme

## Overview

`ColorTheme` is the canonical, app-wide representation of a color scheme: a plain value type that carries a terminal palette (`foreground`, `background`, `cursor`, `selection` and 16 `ansi` colors), identity and lock metadata (`id`, `name`, `appearance`, `isBuiltIn`, `isImported`, `attribution`), optional explicit colors for app-wide semantic roles (`roleOverrides`), a `typography` value, and optional per-feature overrides (`terminal`, `project`). It is a strict superset of a terminal profile's appearance, so a `.itermcolors` file maps directly onto the palette portion.

The file also declares `ThemeAppearance` (`dark`, `light`, `auto`). The type is logic only: it holds data, derives editability from two flags, and decodes older persisted shapes. Palette parsing, semantic-role derivation, the catalog, and persistence live in sibling types (`ITermColorsParser`, `SemanticPalette`, `ThemeStore`, `ThemeStorage`) and are outside this recipe. Colors are `RGBAColor` values, each encoded as an `#RRGGBBAA` string, so a whole theme round-trips through `UserDefaults`.

## Behavioral Requirements

### ThemeAppearance

- **appearance-cases**: `ThemeAppearance` MUST have exactly three cases, `dark`, `light` and `auto`, each encoded as its lowercase name.
- **appearance-identifier**: `ThemeAppearance.id` MUST equal its raw value.
- **appearance-enumerable**: `ThemeAppearance` MUST be enumerable as a collection of all cases and MUST be safe to share across concurrency domains.

### ColorTheme data shape

- **theme-value-type**: `ColorTheme` MUST be a value type that is `Codable`, `Identifiable`, `Equatable` and safe to share across concurrency domains, identified by its `id` string.
- **identity-fields**: `ColorTheme` MUST carry `id` (String), `name` (String), `appearance` (`ThemeAppearance`), `isBuiltIn` (Bool), `isImported` (Bool) and `attribution` (optional String).
- **palette-fields**: `ColorTheme` MUST carry `foreground`, `background`, `cursor` and `selection` as `RGBAColor`, and `ansi` as an array of `RGBAColor` holding indices 0 to 15 (0 to 7 normal, 8 to 15 bright).
- **role-overrides-field**: `ColorTheme` MUST carry `roleOverrides` as a dictionary from `ThemeRole.rawValue` strings to `RGBAColor`.
- **role-overrides-precedence**: A role present in `roleOverrides` MUST win over the value derived from the palette. `ColorTheme` only stores the overrides; the derivation and the precedence are implemented by `SemanticPalette`, named in the source doc comment.
- **typography-field**: `ColorTheme` MUST carry `typography` as a `ThemeTypography`, defaulting to `ThemeTypography.system`.
- **feature-override-fields**: `ColorTheme` MUST carry `terminal` (optional `ThemeTerminalOptions`) and `project` (optional `ThemeProjectOptions`). `nil` MUST mean the Terminal or Projects settings panel decides.
- **color-encoding**: Every color field MUST encode as an `#RRGGBBAA` hex string through `RGBAColor`, and a malformed hex string MUST fail decoding with a data-corrupted error (behavior of `RGBAColor`, which clamps constructed components to the range 0 to 1).

### Initialization

- **init-defaults**: The memberwise initializer MUST default `id` to a fresh `UUID().uuidString`, `isBuiltIn` and `isImported` to `false`, `attribution` to `nil`, `roleOverrides` to an empty dictionary, `typography` to `.system`, and `terminal` and `project` to `nil`.
- **init-required**: The memberwise initializer MUST require `name`, `appearance`, `foreground`, `background`, `cursor`, `selection` and `ansi`.
- **init-no-validation**: The initializer MUST NOT validate the palette; a theme with any number of `ansi` colors can be constructed.

### Decoding

- **decode-required-keys**: Decoding MUST fail when any of `id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `selection` or `ansi` is absent.
- **decode-lock-flags-default**: Decoding MUST treat an absent `isBuiltIn` or `isImported` as `false`. A hand-authored theme file does not carry them, and the import path overwrites them anyway.
- **decode-attribution-default**: Decoding MUST treat an absent `attribution` as `nil`.
- **decode-role-overrides-default**: Decoding MUST treat an absent `roleOverrides` as an empty dictionary.
- **decode-typography-default**: Decoding MUST treat an absent `typography` as `.system`, so themes persisted before typography existed still load.
- **decode-feature-options-absent**: Decoding MUST treat an absent `terminal` or `project` as `nil`. Absent is the meaningful state, not a migration fallback.
- **decode-no-palette-validation**: Decoding MUST NOT reject an `ansi` array whose length is not 16; length is checked by callers through `hasValidPalette`.
- **codable-round-trip**: Encoding a theme and decoding the result MUST yield an equal theme, provided each color sits on the 8-bit grid.

### Derived properties

- **ansi-color-count**: `ColorTheme.ansiColorCount` MUST be `16`.
- **has-valid-palette**: `hasValidPalette` MUST be `true` exactly when `ansi.count` equals `ansiColorCount`.
- **ansi-color-lookup**: `ansiColor(at:)` MUST return the color at the index when it is within `ansi.indices`, and `nil` for any other index, including negative ones.
- **is-editable**: `isEditable` MUST be `true` exactly when `isBuiltIn` and `isImported` are both `false`.
- **is-locked**: `isLocked` MUST be the inverse of `isEditable`.
- **is-deletable**: `isDeletable` MUST be `true` exactly when `isBuiltIn` is `false`, so imported and custom themes can be deleted and built-ins never can.
- **duplicate-is-custom**: A duplicate of a locked theme is a plain custom theme (`isBuiltIn == false`, `isImported == false`) and is editable. `ColorTheme` expresses this only through the flag logic; the duplicate operation lives in the caller.

### Ordering and side effects

- **no-side-effects**: Every operation of `ColorTheme` MUST be synchronous and free of side effects (no files, network, notifications or logging). Persistence is the job of `ThemeStorage`.

## Appearance

Not applicable — this is a data model, not a visual component.

## States

Not applicable — this is a data model, not a visual component. It has no runtime state machine; the lock state is a pure function of `isBuiltIn` and `isImported` (see `is-editable` and `is-deletable`).

## Accessibility

Not applicable — this is a data model, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| color-theme-001 | codable-round-trip, color-encoding | Test `round-trips through Codable`: a built-in theme with `roleOverrides` set to accent `#11223344`, encoded then decoded | Decoded theme equals the original |
| color-theme-002 | codable-round-trip, identity-fields | Test `attribution and isImported round-trip through Codable`: a theme with `isImported = true` and `attribution = "Arctic Ice Studio"` | Decoded theme equals the original; `isImported` is true; `attribution` is "Arctic Ice Studio" |
| color-theme-003 | decode-lock-flags-default | Test `a shared/hand-authored theme JSON that omits isBuiltIn still decodes`: JSON with no `isBuiltIn`, `isImported`, `roleOverrides` or `typography` keys and 16 ANSI colors | Decodes; `isBuiltIn` false; `isImported` false |
| color-theme-004 | decode-attribution-default, decode-lock-flags-default | Test `themes persisted before isImported/attribution existed still decode`: JSON with `isBuiltIn:false` and no `isImported` or `attribution` | `isImported` false; `attribution` nil |
| color-theme-005 | is-editable, is-locked, is-deletable | Test `editability`: a built-in; the same theme with `isImported = true` and `isBuiltIn = false`; the same with both false | Built-in: locked, not editable, not deletable. Imported: locked, not editable, deletable. Custom: editable, not locked, deletable |
| color-theme-006 | ansi-color-lookup | Test `ansiColor(at:) returns the color in range and nil out of range`: indexes 0, 15, 16, -1 on a built-in | `ansi[0]`, `ansi[15]`, nil, nil |
| color-theme-007 | has-valid-palette, ansi-color-count, init-no-validation | Test `hasValidPalette requires exactly 16 ANSI colors`: a built-in, and a theme constructed with 3 ANSI colors | Built-in true; the 3-color theme constructs and reports false |
| color-theme-008 | color-encoding | Test `RGBAColor clamps out-of-range and non-finite components to [0, 1]`: components 1.5, -0.2, 2.0, 9 and NaN, 0.5, +infinity, -infinity | 1, 0, 1, 1 and 0, 0.5, 1, 0 |
| color-theme-009 | decode-required-keys | JSON with every key except `ansi` | Decoding throws |
| color-theme-010 | decode-role-overrides-default, decode-typography-default, decode-feature-options-absent | The JSON from color-theme-003 | `roleOverrides` is empty; `typography == .system`; `terminal` and `project` are nil |
| color-theme-011 | init-defaults, init-required | Initializer with only the required arguments, called twice | Both `id` values are UUID strings and differ; `isBuiltIn`, `isImported` false; `attribution` nil; `roleOverrides` empty |
| color-theme-012 | appearance-cases, appearance-identifier | `ThemeAppearance.allCases` and `.auto.id` | Three cases `dark`, `light`, `auto`; id "auto" |
| color-theme-013 | decode-no-palette-validation | JSON with 3 ANSI colors | Decodes; `hasValidPalette` is false |
| color-theme-014 | color-encoding | JSON whose `foreground` is "not-a-color" | Decoding throws a data-corrupted error |

## Edge Cases

- **Empty ansi array**: decoding and construction MUST succeed; `hasValidPalette` is false and `ansiColor(at: 0)` is nil.
- **More than 16 ansi colors**: decoding and construction MUST succeed; `hasValidPalette` is false; indices above 15 that exist in the array are still returned by `ansiColor(at:)`.
- **Negative or out-of-range index**: `ansiColor(at:)` MUST return nil and MUST NOT trap.
- **Both lock flags true**: `isEditable` is false and `isDeletable` is false (the built-in rule wins for deletion).
- **Unknown keys in JSON**: decoding MUST ignore them (the custom decoder reads only the known keys).
- **Malformed color string or wrong type**: decoding MUST throw and the theme is not produced; there is no partial theme.
- **Unknown appearance string**: decoding MUST throw, because `appearance` is required and `ThemeAppearance` accepts only its three raw values.
- **Unknown `roleOverrides` key**: stored as given; `ColorTheme` does not check keys against `ThemeRole`.
- **Boundary color components**: values outside 0 to 1 and non-finite values are clamped by `RGBAColor` before they reach the theme.
- **Concurrent access**: `ColorTheme` is a `Sendable` value type with no shared mutable state, so each copy is independent and no ordering rule applies.
- **Offline, cancellation, timeout**: not applicable; the type does no I/O and has no asynchronous operation.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| id | String | `UUID().uuidString` | Built-ins use fixed UUID strings; imported and custom themes get a fresh one |
| name | String | required | Display name |
| appearance | ThemeAppearance | required | `dark`, `light` or `auto` |
| isBuiltIn | Bool | `false` | Read-only and never deletable |
| isImported | Bool | `false` | Read-only but deletable |
| attribution | String? | `nil` | Free-form credit, preserved on export |
| foreground, background, cursor, selection | RGBAColor | required | Terminal palette |
| ansi | [RGBAColor] | required | 16 colors expected (`ansiColorCount`) |
| roleOverrides | [String: RGBAColor] | empty | Keyed by `ThemeRole.rawValue` |
| typography | ThemeTypography | `.system` | Fonts per `TextRole` plus a size scale |
| terminal | ThemeTerminalOptions? | `nil` | Terminal padding, font and caret overrides |
| project | ThemeProjectOptions? | `nil` | Project-window chrome overrides |

## Deep Linking

Not applicable: `ColorTheme` is a data model with no URL, route or scheme handling in its source.

## Localization

Not applicable: `ColorTheme` contains no user-facing strings; the user-facing import error text lives in `ThemeStore`, not in this type.

## Accessibility Options

Not applicable: `ColorTheme` is a data model and reads no system display options. Rendering, contrast and motion are decided by the code that consumes a theme.

## Feature Flags

Not applicable: the source of `ColorTheme` reads no feature flag.

## Analytics

Not applicable: the source of `ColorTheme` emits no analytics event.

## Privacy

Not applicable: `ColorTheme` holds color values, a name and an optional credit string, collects nothing and transmits nothing; storage is handled by `ThemeStorage`.

## Logging

Not applicable: the source of `ColorTheme` makes no log call.

## Platform Notes

- **SwiftUI**: Source platform. The file is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ColorTheme.swift` and imports only Foundation. `RGBAColor` is the bridge to SwiftUI `Color`; convert at the view edge and keep the model free of UI types. A custom `init(from:)` with `decodeIfPresent` supplies the migration defaults; the synthesized `encode(to:)` writes every field.
- **Compose**: Use a Kotlin data class with default parameter values and kotlinx.serialization, where properties with defaults decode as absent-tolerant by default. Store colors as ARGB `Long` or a small value class with a custom serializer emitting `#RRGGBBAA` (the alpha position differs from Android's `#AARRGGBB`). Build a Compose `Color` at the UI edge.
- **React/Web**: Use a TypeScript interface with optional fields and a decode function that fills defaults and throws on a missing required key. Colors are hex strings; browsers accept 8-digit hex with alpha last, matching the source. Derived flags become plain functions or getters.
- **AppKit / UIKit**: Same Swift type. Convert `RGBAColor` to `NSColor` or `UIColor` in an extension in the UI layer; `ThemeAppearance` maps to the dark and light `NSAppearance` names or `UIUserInterfaceStyle`, with `auto` meaning follow the system.
- **WinUI 3**: Model it as a C# `record` (or an immutable class) with `init` properties and defaults, serialized with `System.Text.Json`. Write a `JsonConverter<RGBAColor>` that reads and writes `#RRGGBBAA` and throws `JsonException` on a malformed string, because `Windows.UI.Color` is ARGB and `Color.FromArgb` takes alpha first. Absent keys fall back to property initializers, and required keys use the `required` modifier or a custom converter that throws. Derived flags are get-only expression-bodied properties. Persist custom themes with `Windows.Storage.ApplicationData.Current.LocalSettings` or a JSON file in `LocalFolder`, behind the same storage interface as `ThemeStorage`. Map `ThemeAppearance` to `ElementTheme.Dark`, `Light` and `Default`, and apply it with `FrameworkElement.RequestedTheme`. Bind to the lock state in XAML through `isLocked`; if the record is immutable, raise `INotifyPropertyChanged` from the owning view model rather than the record.

## Design Decisions

**Decision**: Decode `isBuiltIn`, `isImported`, `roleOverrides` and `typography` with defaults when absent, instead of failing.
**Rationale**: Source comments say hand-authored or third-party files lack the lock flags, the import path overwrites them, and themes persisted or exported by older builds predate the later fields. A custom `init(from:)` keeps those files loading.
**Approved**: pending

**Decision**: Keep `terminal` and `project` optional, with `nil` meaning the settings panel decides.
**Rationale**: The source comment calls absent "the meaningful state, not a migration fallback": a theme never given overrides has none.
**Approved**: pending

**Decision**: Do not validate the 16-color palette in the initializer or decoder; expose `hasValidPalette` and `ansiColorCount` instead.
**Rationale**: Validation is offered as a query. `ThemeStore` rejects an invalid palette at import (`ThemeImportError.invalidPalette`), so the model can load any stored shape.
**Approved**: pending

**Decision**: Imported themes are locked like built-ins but remain deletable.
**Rationale**: The source documents that locked themes are edited by duplicating; only built-ins are permanent. A duplicate carries both flags false and edits freely.
**Approved**: pending

**Decision**: Store semantic overrides as strings keyed by `ThemeRole.rawValue`.
**Rationale**: A string key keeps the persisted format stable if roles are added; roles without an override are derived from the palette by `SemanticPalette`, and overrides always win.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

`ColorTheme` is a Foundation-only value type; persistence, parsing, derivation and the catalog sit in sibling types, so separation of concerns passes. `ColorThemeTests` covers round trips, legacy decoding, editability, ANSI indexing and palette validity, but nothing asserts the decode defaults for `roleOverrides`, `typography`, `terminal` and `project`, a missing required key, or a malformed color string, so unit-test coverage is partial. Data integrity is partial because the decoder and initializer accept any number of ANSI colors and rely on callers to check `hasValidPalette`. The type holds only colors, names and an optional credit string, which passes data minimization.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | | | Initial creation |
