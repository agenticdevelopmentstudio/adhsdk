---
id: 932449c9-b57f-4e2c-992a-1e27584742b6
title: "ColorTheme"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The app-wide color theme value type: terminal palette, identity and lock flags, semantic role overrides, typography and per-feature options, with tolerant Codable decoding."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - color
  - model
  - codable
depends-on:
  - ad5bae6b-0172-4cd4-a4b7-297eb58eb28d
  - ccc0d121-4927-4a83-b0e5-337116edebc0
  - 794a60b5-7833-4dc3-a7b9-8280333cde8b
related:
  - 0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6
  - 1f80f43d-5aa4-42cf-bc3e-fb742662b615
  - 62abe97d-75f7-48c0-83cd-6df02a48515e
  - d15bba09-4574-4fd1-93a0-f7d2cccd04f2
references: []
approved-by: ""
approved-date: ""
---

# ColorTheme

## Overview

`ColorTheme` is the canonical, app-wide representation of a color scheme: a plain value type that carries a terminal palette (`foreground`, `background`, `cursor`, `selection` and 16 `ansi` colors), identity and lock metadata (`id`, `name`, `appearance`, `isBuiltIn`, `isImported`, `attribution`), optional explicit colors for app-wide semantic roles (`roleOverrides`), a `typography` value (`ThemeTypography` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.theme-typography](cookbook:ccc0d121-4927-4a83-b0e5-337116edebc0))), and optional per-feature overrides (`terminal`, `project`; see `ThemeOptions` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.theme-options](cookbook:794a60b5-7833-4dc3-a7b9-8280333cde8b))). It is a strict superset of a terminal profile's appearance, so a `.itermcolors` file maps directly onto the palette portion.

The file also declares `ThemeAppearance` (`dark`, `light`, `auto`). The type is logic only: it holds data, derives editability from two flags, and decodes older persisted shapes. Palette parsing, semantic-role derivation, the catalog, and persistence live in sibling types (`ITermColorsParser` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.i-term-colors-parser](cookbook:231a7e9a-8c03-44b3-afaf-b71755e05c1d)), `SemanticPalette` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.semantic-palette](cookbook:1f80f43d-5aa4-42cf-bc3e-fb742662b615)), `ThemeStore` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.theme-store](cookbook:d15bba09-4574-4fd1-93a0-f7d2cccd04f2)), `ThemeStorage` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.theme-storage](cookbook:62abe97d-75f7-48c0-83cd-6df02a48515e))) and are outside this ingredient. Colors are RGBAColor ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.rgba-color](cookbook:ad5bae6b-0172-4cd4-a4b7-297eb58eb28d)) values, each encoded as an `#RRGGBBAA` string, so a whole theme round-trips through `UserDefaults`.

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
- **role-overrides-precedence**: `ColorTheme` MUST store `roleOverrides` exactly as given and MUST NOT drop, reorder or rewrite entries. Note (non-normative): that an override wins over the palette-derived value is implemented by `SemanticPalette` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.semantic-palette](cookbook:1f80f43d-5aa4-42cf-bc3e-fb742662b615)), not by this type.
- **typography-field**: `ColorTheme` MUST carry `typography` as a `ThemeTypography`, defaulting to `ThemeTypography.system`.
- **feature-override-fields**: `ColorTheme` MUST carry `terminal` (optional `ThemeTerminalOptions`) and `project` (optional `ThemeProjectOptions`). `nil` MUST mean the Terminal or Projects settings panel decides.
- **color-encoding**: Every color field MUST encode as an `#RRGGBBAA` hex string through `RGBAColor`, and a malformed hex string MUST fail decoding with a data-corrupted error. Hex parsing and component clamping are owned by RGBAColor ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.rgba-color](cookbook:ad5bae6b-0172-4cd4-a4b7-297eb58eb28d)) and are not specified here.

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
- **encode-omits-nil**: Encoding MUST omit `attribution`, `terminal` and `project` when they are `nil`, and MUST NOT write a null for them.
- **codable-round-trip**: Encoding a theme and decoding the result MUST yield an equal theme, provided each color sits on the 8-bit grid.

### Derived properties

- **ansi-color-count**: `ColorTheme.ansiColorCount` MUST be `16`.
- **has-valid-palette**: `hasValidPalette` MUST be `true` exactly when `ansi.count` equals `ansiColorCount`.
- **ansi-color-lookup**: `ansiColor(at:)` MUST return the color at the index when it is within `ansi.indices`, and `nil` for any other index, including negative ones.
- **is-editable**: `isEditable` MUST be `true` exactly when `isBuiltIn` and `isImported` are both `false`.
- **is-locked**: `isLocked` MUST be the inverse of `isEditable`.
- **is-deletable**: `isDeletable` MUST be `true` exactly when `isBuiltIn` is `false`, so imported and custom themes can be deleted and built-ins never can.
- **duplicate-is-custom**: A theme with `isBuiltIn == false` and `isImported == false` MUST be editable and deletable, however it was made. A caller that duplicates a locked theme and clears both flags therefore gets an editable theme. The duplicate operation itself lives in the caller.

### Ordering and side effects

- **no-side-effects**: Every operation of `ColorTheme` MUST be synchronous and free of side effects (no files, network, notifications or logging). Persistence is the job of `ThemeStorage` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.theme-storage](cookbook:62abe97d-75f7-48c0-83cd-6df02a48515e)).

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
| color-theme-008 | color-encoding | Test (exercises `RGBAColor`, the owner of clamping) `RGBAColor clamps out-of-range and non-finite components to [0, 1]`: components 1.5, -0.2, 2.0, 9 and NaN, 0.5, +infinity, -infinity | 1, 0, 1, 1 and 0, 0.5, 1, 0 |
| color-theme-009 | decode-required-keys | JSON with every key except `ansi` | Decoding throws |
| color-theme-010 | decode-role-overrides-default, decode-typography-default, decode-feature-options-absent | The JSON from color-theme-003 | `roleOverrides` is empty; `typography == .system`; `terminal` and `project` are nil |
| color-theme-011 | init-defaults, init-required | Initializer with only the required arguments, called twice | Both `id` values are UUID strings and differ; `isBuiltIn`, `isImported` false; `attribution` nil; `roleOverrides` empty |
| color-theme-012 | appearance-cases, appearance-identifier, appearance-enumerable | `ThemeAppearance.allCases` and `.auto.id` | Three cases `dark`, `light`, `auto`; id "auto" |
| color-theme-013 | decode-no-palette-validation | JSON with 3 ANSI colors | Decodes; `hasValidPalette` is false |
| color-theme-014 | color-encoding | JSON whose `foreground` is "not-a-color" | Decoding throws a data-corrupted error |
| color-theme-015 | is-editable, is-deletable, is-locked | A theme with `isBuiltIn = true` and `isImported = true` | `isEditable` false; `isLocked` true; `isDeletable` false |
| color-theme-016 | decode-no-palette-validation, ansi-color-lookup | JSON with 17 ANSI colors; then `ansiColor(at: 16)` | Decodes; `hasValidPalette` false; `ansiColor(at: 16)` returns the 17th color |
| color-theme-017 | decode-required-keys | The JSON from color-theme-003 plus an unknown key `"extra": 1` | Decodes; the theme equals the one decoded without the key |
| color-theme-018 | appearance-cases | JSON whose `appearance` is "sepia" | Decoding throws |
| color-theme-019 | encode-omits-nil | Encode a theme with `attribution`, `terminal` and `project` nil | The JSON object has no `attribution`, `terminal` or `project` key |
## Edge Cases

- **Empty ansi array** (see `decode-no-palette-validation`): decoding and construction MUST succeed; `hasValidPalette` is false and `ansiColor(at: 0)` is nil.
- **More than 16 ansi colors**: decoding and construction MUST succeed; `hasValidPalette` is false; indices above 15 that exist in the array are still returned by `ansiColor(at:)`.
- **Negative or out-of-range index**: `ansiColor(at:)` MUST return nil and MUST NOT trap.
- **Both lock flags true**: `isEditable` is false and `isDeletable` is false (the built-in rule wins for deletion).
- **Unknown keys in JSON**: decoding MUST ignore them (the custom decoder reads only the known keys). Ports MUST configure their decoder to ignore unknown keys.
- **Malformed color string or wrong type**: decoding MUST throw and the theme is not produced; there is no partial theme.
- **Unknown appearance string**: decoding MUST throw, because `appearance` is required and `ThemeAppearance` accepts only its three raw values.
- **Unknown `roleOverrides` key**: stored as given; `ColorTheme` does not check keys against `ThemeRole`.
- **Boundary color components**: values outside 0 to 1 and non-finite values are clamped by RGBAColor ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.rgba-color](cookbook:ad5bae6b-0172-4cd4-a4b7-297eb58eb28d)) before they reach the theme.
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

- **SwiftUI**: Source platform. The file is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ColorTheme.swift` and imports only Foundation. `RGBAColor` is the bridge to SwiftUI `Color`; convert at the view edge and keep the model free of UI types. A custom `init(from:)` with `decodeIfPresent` supplies the migration defaults; the synthesized `encode(to:)` writes every field except `nil` optionals (`attribution`, `terminal`, `project`), which it omits.
- **Compose**: Use a Kotlin data class with default parameter values and kotlinx.serialization, where properties with defaults decode as absent-tolerant by default. Configure `Json { ignoreUnknownKeys = true }`, because kotlinx.serialization rejects unknown keys by default, and `explicitNulls = false` so `nil` optionals are omitted on encode. Store colors as ARGB `Long` or a small value class with a custom serializer emitting `#RRGGBBAA` (the alpha position differs from Android's `#AARRGGBB`). Build a Compose `Color` at the UI edge.
- **React/Web**: Use a TypeScript interface with optional fields and a decode function that fills defaults and throws on a missing required key. Colors are hex strings; browsers accept 8-digit hex with alpha last, matching the source. Derived flags become plain functions or getters.
- **AppKit / UIKit**: Same Swift type. Convert `RGBAColor` to `NSColor` or `UIColor` in an extension in the UI layer; `ThemeAppearance` maps to the dark and light `NSAppearance` names or `UIUserInterfaceStyle`, with `auto` meaning follow the system.
- **WinUI 3**: Model it as a C# `record` (or an immutable class) with `init` properties and defaults, serialized with `System.Text.Json`. Write a `JsonConverter<RGBAColor>` that reads and writes `#RRGGBBAA` and throws `JsonException` on a malformed string, because `Windows.UI.Color` is ARGB and `Color.FromArgb` takes alpha first. Absent keys fall back to property initializers, and required keys use the `required` modifier or a custom converter that throws. Derived flags are get-only expression-bodied properties. Map `ThemeAppearance` to `ElementTheme.Dark`, `Light` and `Default`, and apply it with `FrameworkElement.RequestedTheme`. Bind to the lock state in XAML through `isLocked`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ColorTheme.swift` | confirmed (1.0.2) |

## Design Decisions

**Decision**: Decode `isBuiltIn`, `isImported`, `roleOverrides` and `typography` with defaults when absent, instead of failing.
**Rationale**: Source comments say hand-authored or third-party files lack the lock flags, the import path overwrites them, and themes persisted or exported by older builds predate the later fields. A custom `init(from:)` keeps those files loading.
**Approved**: pending

**Decision**: Keep `terminal` and `project` optional, with `nil` meaning the settings panel decides.
**Rationale**: The source comment calls absent "the meaningful state, not a migration fallback": a theme never given overrides has none.
**Approved**: pending

**Decision**: Do not validate the 16-color palette in the initializer or decoder; expose `hasValidPalette` and `ansiColorCount` instead.
**Rationale**: Validation is offered as a query, so the model can load any stored shape. The debt is that an invalid palette (and an unknown `roleOverrides` key) is accepted silently unless the caller asks. The only caller of `hasValidPalette` in source is `ThemeStore` import (`ThemeStore.swift`), which rejects an invalid palette with `ThemeImportError.invalidPalette`; theme builders such as `VSCodeThemeImporter` produce 16 colors by construction. Any new entry point that accepts a theme MUST check `hasValidPalette` itself.
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
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

`ColorTheme` is a Foundation-only value type; persistence, parsing, derivation and the catalog sit in sibling types, so separation of concerns passes. `ColorThemeTests` (`packages/apple/AgenticDeveloperHubSDK/SDK/Tests/AgenticDeveloperHubSDKTests/Theme/ColorThemeTests.swift`) covers all 19 vectors: round trips, legacy decoding, editability, ANSI indexing, palette validity, the decode defaults, a missing required key and a malformed color string, so unit-test coverage passes. Data integrity is partial because the decoder and initializer accept any number of ANSI colors and rely on callers to check `hasValidPalette`. The type holds only colors, names and an optional credit string, which passes data minimization.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ColorThemeTests.swift, 19 of 19 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Linked RGBAColor, typography, options and sibling ingredients in depends-on and the text, set the author, moved clamping to RGBAColor, added encode-omits-nil and five vectors, marked untested vectors, and corrected the SwiftUI, Compose and WinUI notes. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
