---
id: 794a60b5-7833-4dc3-a7b9-8280333cde8b
title: "ThemeOptions"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Optional per-theme overrides for terminal padding, font and caret and for project-window chrome, where nil means the matching settings panel decides."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - settings
  - codable
  - logic
depends-on: []
related:
  - ad5bae6b-0172-4cd4-a4b7-297eb58eb28d
  - 932449c9-b57f-4e2c-992a-1e27584742b6
references: []
approved-by: ""
approved-date: ""
---

# ThemeOptions

## Overview

`ThemeOptions` is the pair of optional override structs a color theme can carry, plus the caret-shape enum one of them uses. `ThemeTerminalOptions` overrides terminal padding, font and caret. `ThemeProjectOptions` overrides the project window's active-pane outline switch, its outline color and the pane backdrop color. The source file also defines `TerminalCursorShape`.

Every field in both structs is optional, and `nil` means "whatever the settings panel says". A theme starts with no opinion and acquires one only for the fields the user edits, so switching themes does not rewrite settings the user never touched. The source file imports only `Foundation`; it lives in the Core layer because a `ColorTheme` carries one of each (see [ColorTheme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6)). The mapping of `TerminalCursorShape` onto SwiftTerm's `CursorStyle` stays in the macOS framework, and the resolution of `nil` against a settings panel lives in the consumers, not here. Colors are [RGBAColor](cookbook:ad5bae6b-0172-4cd4-a4b7-297eb58eb28d) values.

## Behavioral Requirements

Cursor shape

- **cursor-shape-cases**: `TerminalCursorShape` MUST have exactly four cases, in this order: `block`, `hollowBlock`, `underline`, `bar`.
- **cursor-shape-raw-value**: `TerminalCursorShape` MUST have a `String` raw value equal to the case name (`"block"`, `"hollowBlock"`, `"underline"`, `"bar"`) and MUST encode and decode as that string.
- **cursor-shape-traits**: `TerminalCursorShape` MUST be `Codable`, `CaseIterable`, `Sendable` and `Equatable`.
- **cursor-shape-no-blink**: `TerminalCursorShape` MUST NOT encode blinking. Blinking is the separate `cursorBlinks` field on `ThemeTerminalOptions`, because the user thinks of "block, blinking" as a shape plus a setting and SwiftTerm's six-case `CursorStyle` is an encoding detail.
- **cursor-shape-label**: `TerminalCursorShape.label` MUST return the literal picker text for each case: `"Block  ▉"`, `"Hollow Block  ▢"`, `"Underline  _"`, `"Bar  |"`. Each has two spaces before the glyph.
- **cursor-shape-decode-unknown**: Decoding a string that is not one of the four raw values MUST fail with the decoder's standard error; the source adds no fallback case.

Terminal options data shape

- **terminal-fields**: `ThemeTerminalOptions` MUST expose eight mutable optional fields: `paddingTop`, `paddingLeading`, `paddingBottom` and `paddingTrailing` (`Int?`), `fontName` (`String?`), `fontSize` (`Double?`), `cursorShape` (`TerminalCursorShape?`) and `cursorBlinks` (`Bool?`).
- **terminal-traits**: `ThemeTerminalOptions` MUST be `Codable`, `Equatable` and `Sendable`. Equality is the synthesized field-by-field comparison.
- **terminal-nil-means-settings**: A `nil` field in `ThemeTerminalOptions` MUST mean the Terminal settings panel value applies. The struct itself performs no resolution.
- **terminal-init-defaults**: The initializer `init(paddingTop:paddingLeading:paddingBottom:paddingTrailing:fontName:fontSize:cursorShape:cursorBlinks:)` MUST default every argument to `nil`, so `ThemeTerminalOptions()` is the no-opinion value.
- **terminal-font-name**: `fontName` MUST hold a PostScript font name, not a family name, because the font picker must tell `FiraCode Nerd Font Mono` from `FiraCode Nerd Font Propo`, which a family name cannot.
- **terminal-is-empty**: `ThemeTerminalOptions.isEmpty` MUST be true exactly when all eight fields are `nil`. It is the state every theme starts in and the one a "use the defaults" reset returns it to.
- **terminal-partial-override**: Setting one field MUST leave the other seven `nil`; a theme carries an opinion only about fields that were set.

Project options data shape

- **project-fields**: `ThemeProjectOptions` MUST expose three mutable optional fields: `highlightActivePane` (`Bool?`), `paneOutline` (`RGBAColor?`) and `paneBackdrop` (`RGBAColor?`).
- **project-traits**: `ThemeProjectOptions` MUST be `Codable`, `Equatable` and `Sendable`.
- **project-nil-means-settings**: A `nil` field in `ThemeProjectOptions` MUST mean the Projects settings panel (or the theme-derived default described next) applies. The struct performs no resolution.
- **project-init-defaults**: `init(highlightActivePane:paneOutline:paneBackdrop:)` MUST default every argument to `nil`.
- **project-highlight-switch**: `highlightActivePane` MUST override `UserSettings.highlightActivePane`, as the source comment states. The switch itself belongs in settings because it is a working preference; the theme overrides it and picks the color because that is an appearance decision.
- **project-outline-default**: When `paneOutline` is `nil`, the consumer MUST draw the theme's outline tone, which the source comment says is what the app draws when no theme has an opinion. The tone derivation is outside this file.
- **project-backdrop-default**: When `paneBackdrop` is `nil`, the consumer MUST use the theme's raised-surface tone, one step off the pane backdrop, so panes read as separate objects rather than one field with seams. The tone derivation is outside this file.
- **project-is-empty**: `ThemeProjectOptions.isEmpty` MUST be true exactly when all three fields are `nil`.

Codable

- **codable-synthesized**: Both structs use compiler-synthesized `Codable`: a keyed container whose keys are the property names, with a `nil` field omitted on encode and an absent or null key decoded as `nil`. The source writes no custom coding, so any JSON object, including `{}`, decodes.
- **codable-color-format**: `paneOutline` and `paneBackdrop` MUST encode as `"#RRGGBBAA"` strings, via `RGBAColor`'s single-value coding, and an unparseable string MUST fail the decode of the enclosing struct.
- **codable-type-mismatch**: A present value of the wrong type (for example a string for `paddingTop`) MUST fail the decode with the decoder's standard error. The source does not coerce.

Concurrency and side effects

- **sendable-values**: Both structs and the enum are `Sendable` value types; an instance copied to another thread MUST be independent of the original, and the source adds no locking.
- **no-side-effects**: No operation in this file MAY perform I/O, logging, notification or persistence. Persistence is the caller's, through `Codable` (the owning `ColorTheme` is stored by its own store).

## Appearance

Not applicable — this is a set of optional override values, not a visual component. The only display text is `TerminalCursorShape.label`, covered under Localization.

## States

Not applicable — these are plain value types, not a visual component. The only state distinction is empty versus non-empty, which is `isEmpty` under Behavioral Requirements.

## Accessibility

Not applicable — this is a data model, not a visual component. The source carries no labels beyond `TerminalCursorShape.label`.

## Conformance Test Vectors

The source has no test file of its own. The only test that names these types is `BubbleTruncationTests` in the macOS test target, which builds `ThemeTerminalOptions(fontName: "Menlo-Bold", fontSize: 21)` as a fixture and asserts nothing about the types. Vectors derive from the source's code and doc comments; the types are otherwise exercised only through `ColorTheme` coding.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| themeoptions-001 | terminal-init-defaults, terminal-is-empty | `ThemeTerminalOptions()` | all eight fields `nil`; `isEmpty` is true |
| themeoptions-002 | terminal-is-empty | `ThemeTerminalOptions(paddingTop: 0)` | `isEmpty` is false; zero is a value, not nil |
| themeoptions-003 | terminal-is-empty | each one of the eight fields set alone | `isEmpty` is false each time |
| themeoptions-004 | terminal-partial-override | `ThemeTerminalOptions(fontSize: 13)` | `fontSize == 13`; the other seven fields are `nil` |
| themeoptions-005 | project-init-defaults, project-is-empty | `ThemeProjectOptions()` | all three fields `nil`; `isEmpty` is true |
| themeoptions-006 | project-is-empty | `ThemeProjectOptions(highlightActivePane: false)` | `isEmpty` is false; `false` is a value, not nil |
| themeoptions-007 | codable-synthesized | encode `ThemeTerminalOptions(paddingTop: 4)` to JSON | object containing only the key `paddingTop` with value 4 |
| themeoptions-008 | codable-synthesized | decode `{}` as `ThemeTerminalOptions` and as `ThemeProjectOptions` | both succeed and `isEmpty` is true |
| themeoptions-009 | cursor-shape-raw-value | encode `TerminalCursorShape.hollowBlock` inside an array | `["hollowBlock"]` |
| themeoptions-010 | cursor-shape-decode-unknown | decode `["triangle"]` as `[TerminalCursorShape]` | throws a decoding error |
| themeoptions-011 | cursor-shape-cases, cursor-shape-traits | `TerminalCursorShape.allCases` | `[.block, .hollowBlock, .underline, .bar]` |
| themeoptions-012 | cursor-shape-label | the four `label` values | `"Block  ▉"`, `"Hollow Block  ▢"`, `"Underline  _"`, `"Bar  |"` |
| themeoptions-013 | cursor-shape-no-blink, terminal-fields | `ThemeTerminalOptions(cursorShape: .bar, cursorBlinks: true)` | shape and blink stored in separate fields; `cursorBlinks == true` |
| themeoptions-014 | codable-color-format, project-fields | encode `ThemeProjectOptions(paneOutline: RGBAColor(hexString: "#336699FF")!)` | JSON key `paneOutline` has the string `"#336699FF"`; the other two keys are absent |
| themeoptions-015 | codable-color-format | decode `{"paneBackdrop":"red"}` as `ThemeProjectOptions` | throws a decoding error |
| themeoptions-016 | codable-type-mismatch | decode `{"paddingTop":"4"}` as `ThemeTerminalOptions` | throws a decoding error |
| themeoptions-017 | terminal-traits, project-traits | two instances built from the same arguments | `==` is true; changing one field makes `==` false |
| themeoptions-018 | codable-synthesized | round trip `ThemeTerminalOptions(paddingTop: 2, paddingLeading: 3, paddingBottom: 4, paddingTrailing: 5, fontName: "FiraCodeNFM-Reg", fontSize: 12.5, cursorShape: .underline, cursorBlinks: false)` | decoded value equals the original |

## Edge Cases

- **Empty or missing data**: `{}` and a missing key decode as `nil`, and the all-nil struct is the valid no-opinion state. A `null` value also decodes as `nil`. MUST.
- **Zero and false are overrides**: `paddingTop: 0` and `highlightActivePane: false` are values, not absence; `isEmpty` is false. MUST.
- **Unvalidated numbers**: the source performs no range check on padding or font size. Negative, zero, NaN or huge values are stored as given. A caller that renders them owns the check; the source documents no range. Stated as a fact.
- **Unvalidated font name**: `fontName` is stored as given, with no check that the font is installed. Resolution of a missing font belongs to the terminal appearance consumer, outside these sources. Stated as a fact.
- **Unknown cursor shape**: a stored raw value outside the four cases fails the decode of the whole struct, and so of the enclosing `ColorTheme`. There is no lenient fallback. MUST.
- **Malformed color string**: an unparseable `paneOutline` or `paneBackdrop` fails the whole struct decode. MUST.
- **Unknown extra keys**: the synthesized decoder ignores keys it does not know, so a theme file written by a newer version loses those keys on the next save. SHOULD be treated as expected.
- **Concurrent access**: all three types are `Sendable` value types with no shared mutable state, so concurrent reads of separate copies cannot race. MUST.
- **Error states, offline state, cancellation and timeouts**: not applicable; every operation is synchronous, local and bounded, and the only failure is a thrown decoding error.

## Configuration

Not applicable: the types read no environment variables or settings keys and take no injected dependencies. The initializer arguments are the whole input and each defaults to `nil`; the settings panels these values override (Terminal, Projects, `UserSettings.highlightActivePane`) are owned by other code.

## Deep Linking

Not applicable: these are value types with no screens or URL routes.

## Localization

`TerminalCursorShape.label` returns hardcoded English strings with a trailing glyph, not looked up through a localization table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal in source) | Block  ▉ | `TerminalCursorShape.block.label`, shown in the cursor-shape picker |
| (none; literal in source) | Hollow Block  ▢ | `TerminalCursorShape.hollowBlock.label` |
| (none; literal in source) | Underline  _ | `TerminalCursorShape.underline.label` |
| (none; literal in source) | Bar  \| | `TerminalCursorShape.bar.label` |

## Accessibility Options

Not applicable: the types hold override values and respond to no display option; they have no rendering code.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the types hold padding numbers, a font name, a caret shape and colors. They collect and transmit nothing, and persistence is whatever the caller does with the encoded theme.

## Logging

Not applicable: the source makes no log calls; failure is a thrown decoding error.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ThemeOptions.swift`, Foundation-only, so it compiles for macOS and iOS. A SwiftUI view reads the override and falls back to its settings value, for example `theme.terminal?.fontSize ?? settings.fontSize`, and builds `Color(.sRGB, red:green:blue:opacity:)` from an `RGBAColor`. The `TerminalCursorShape` to SwiftTerm `CursorStyle` mapping is in `TerminalAppearance.swift` in the macOS framework.
- **Compose**: Use immutable Kotlin `data class` values with nullable properties and an enum class for the caret shape; `kotlinx.serialization` omits default-null properties when `encodeDefaults` is false, matching the omitted-nil behavior. Resolve with the Elvis operator against the settings value. Padding maps to `PaddingValues(start, top, end, bottom)`, where leading and trailing become start and end for right-to-left layouts.
- **React/Web**: Port as TypeScript interfaces with optional properties (`paddingTop?: number`) and a string-literal union for the shape. `JSON.stringify` omits `undefined`, and decode must treat both a missing key and `null` as unset. Compare with `== null`, not truthiness, so `0` and `false` stay overrides. `isEmpty` is `Object.values(x).every(v => v == null)`.
- **AppKit / UIKit**: The macOS panels are `ThemeTerminalTopicPanel.swift` and `ThemeProjectTopicPanel.swift`; `TerminalAppearance.swift` resolves the options against the Terminal settings. On iOS the same structs apply unchanged; padding becomes `NSDirectionalEdgeInsets` (leading and trailing, not left and right) and the font is resolved with `UIFont(name:size:)` from the PostScript name.
- **WinUI 3**: Make each struct an immutable `sealed record` (or a class implementing `INotifyPropertyChanged` if a settings page edits it in place) with nullable members: `int?` padding, `string?` `FontName`, `double?` `FontSize`, `bool?` `CursorBlinks`, and an `enum TerminalCursorShape { Block, HollowBlock, Underline, Bar }`. Serialize with `System.Text.Json`: set `JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull` to omit nulls, and add `JsonStringEnumConverter` with `JsonNamingPolicy.CamelCase` so the shape writes as `"hollowBlock"`; an unknown enum string then throws `JsonException`, matching the source. Colors need a `JsonConverter<RGBAColor>` reading one `#RRGGBBAA` string. Map padding to `Microsoft.UI.Xaml.Thickness(left, top, right, bottom)`, passing leading as left (swap for `FlowDirection.RightToLeft`). Resolve overrides with `??` against the settings value, applying to a terminal host's `FontFamily` (a family name, so keep a PostScript-to-family lookup, since WinUI `FontFamily` does not select by PostScript name), `FontSize` and caret. The `label` text belongs in a `.resw` resource; render the picker as a `ComboBox` over `Enum.GetValues`. Persist with `Windows.Storage.ApplicationData.Current.LocalSettings` or a JSON file in `LocalFolder`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ThemeOptions.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Every field is optional and `nil` means the settings panel decides.
**Rationale**: The source comment states a theme starts with no opinion and only acquires one for fields the user edits, so switching themes does not silently rewrite settings the user never touched (`principle-of-least-astonishment`).
**Approved**: pending

**Decision**: Cursor blinking is a separate `cursorBlinks` field, not extra enum cases.
**Rationale**: The source comment says "block, blinking" is how the user thinks about it and SwiftTerm's six-case `CursorStyle` is an encoding detail.
**Approved**: pending

**Decision**: `TerminalCursorShape` and both option structs live in Core, with the SwiftTerm mapping in the macOS framework.
**Rationale**: A `ColorTheme` carries one of each and Core is Foundation-only; the macOS framework is the only place that knows SwiftTerm exists.
**Approved**: pending

**Decision**: `fontName` is a PostScript name.
**Rationale**: The font picker must distinguish `FiraCode Nerd Font Mono` from `FiraCode Nerd Font Propo`, which share a family name.
**Approved**: pending

**Decision**: The active-pane switch lives in settings, while the theme overrides it and owns the color.
**Rationale**: The source comment calls the switch a working preference and the color an appearance decision.
**Approved**: pending

**Decision**: The `nil` backdrop is the theme's raised-surface tone, one step off the pane backdrop.
**Rationale**: The source comment says this makes panes read as separate objects rather than one field with seams.
**Approved**: pending

**Decision**: No value is validated and no decode fallback exists.
**Rationale**: The source is a plain data holder using synthesized coding; range checks and missing-font handling belong to the consumers. This is technical debt only in that a bad number from a hand-edited theme reaches rendering unchanged.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

Separation of concerns passes because the file holds only override values, the caret-shape enum and `isEmpty`; resolution against settings, tone derivation and the SwiftTerm mapping live in other files. Unit-test coverage fails because the only test that names these types (`BubbleTruncationTests`) uses `ThemeTerminalOptions` as a fixture, so the `isEmpty` logic, the synthesized coding and the shape raw values have no direct assertions. No-hardcoded-strings fails because `TerminalCursorShape.label` returns English literals with glyphs, not table lookups. Data integrity is partial: the structs store padding, font size and font name without any range or existence check, and an unknown cursor-shape string fails the whole theme decode.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
