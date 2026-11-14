---
id: 359491fd-36ee-4e07-9971-76260183f243
title: "Built-In Themes"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "The catalogue of built-in color themes the SDK ships: 15 hand-authored schemes plus the web-ported set, a stable default ID, and lookup by ID."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - color
  - built-in
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Built-In Themes

## Overview

`BuiltInThemes` is a caseless Swift `enum` that acts as a namespace and static catalogue of the color themes the toolkit ships. It is the single source of truth for the bundled schemes: its doc comment states that the terminal feature derives its built-in profiles from this list (through `ColorTheme.terminalPalette`), so a theme is defined exactly once.

The catalogue has two parts. `handAuthored` is the original curated set of 15 themes. Each carries a 16-color terminal palette and explicit app-chrome role overrides (surface, elevated surface, control background, border, outline) taken from the scheme's own published panel and line colors. `all` is `handAuthored` followed by `webPortedNative`, the 21 themes ported from the web catalogue with their native adjustments (defined in `BuiltInThemes+Web.swift` and `BuiltInThemes+Native.swift`, which this recipe does not specify beyond how `all` composes them).

The type also exposes `defaultID` (Solarized Dark), `theme(withID:)` for lookup, and two private helpers: `chrome(...)`, which builds the five-role override dictionary, and `rgb(_:)`, which turns a hex literal into an opaque `RGBAColor`. Text, accent and status roles are not set here; they derive from the palette in `SemanticPalette`, which guarantees their contrast.

## Behavioral Requirements

### Catalogue composition

- **all-composition**: `BuiltInThemes.all` MUST equal `handAuthored` followed by `webPortedNative`, in that order, with `handAuthored` first.
- **all-count**: `BuiltInThemes.all` MUST contain 36 themes (15 hand-authored and 21 web-ported), as asserted by the `count` test.
- **hand-authored-order**: `BuiltInThemes.handAuthored` MUST list its 15 themes in this order: Solarized Dark, Solarized Light, Dracula, Nord, Tokyo Night, One Dark, Monokai Pro, Rosé Pine, Catppuccin Mocha, Catppuccin Latte, Ayu Dark, GitHub Dark, GitHub Light, Gruvbox Dark, Gruvbox Light.
- **hand-authored-appearance**: Among the hand-authored themes, 11 MUST declare `appearance` as `.dark` (Solarized Dark, Dracula, Nord, Tokyo Night, One Dark, Monokai Pro, Rosé Pine, Catppuccin Mocha, Ayu Dark, GitHub Dark, Gruvbox Dark) and 4 MUST declare `.light` (Solarized Light, Catppuccin Latte, GitHub Light, Gruvbox Light). None declares `.auto`.
- **hand-authored-scope**: `handAuthored` is internal to the module, not public. It MUST stay separate from `all` so tests about the app-chrome override promise can scope to the themes that make it. The web-ported themes carry chat overrides straight from the web CSS and let chrome derive.

### Theme identity

- **built-in-flag**: Every theme in `all` MUST have `isBuiltIn` equal to `true`.
- **unique-ids**: Every theme in `all` MUST have an `id` distinct from every other theme in `all`.
- **stable-ids**: Each theme's `id` MUST NOT change between releases. The doc comment states the IDs are stable UUID strings shared with the terminal feature's historical profile IDs, so persisted "active theme" selections survive upgrades.
- **hand-authored-id-scheme**: The hand-authored themes use IDs of the form `A1B2C3D4-00NN-4000-8000-0000000000NN`, where `NN` runs from 01 to 15 and is assigned by the theme's original position in the historical profile list, not by `handAuthored` order (for example Solarized Dark is 01, Solarized Light is 02, GitHub Light is 06, Gruvbox Dark is 07, Catppuccin Mocha is 08).
- **attribution-present**: Every hand-authored theme MUST carry a non-nil `attribution` naming the scheme's author or source (for example Solarized Dark carries "Ethan Schoonover").

### Default and lookup

- **default-id**: `BuiltInThemes.defaultID` MUST be the string `A1B2C3D4-0001-4000-8000-000000000001`, the ID of Solarized Dark.
- **default-resolves**: `theme(withID: BuiltInThemes.defaultID)` MUST return the theme named "Solarized Dark".
- **lookup-hit**: `theme(withID:)` MUST return the first theme in `all` whose `id` equals the argument.
- **lookup-miss**: `theme(withID:)` MUST return `nil` when no theme in `all` has that `id`.
- **lookup-exact-match**: `theme(withID:)` MUST compare the ID as an exact `String` equality, so a differently cased UUID string does not match.

### Palette data

- **ansi-count**: Every hand-authored theme MUST carry exactly 16 `ansi` colors, indices 0 to 7 normal and 8 to 15 bright, so `hasValidPalette` is true.
- **opaque-colors**: Every color a built-in constant supplies (foreground, background, cursor, selection, ansi entries, and role overrides) MUST be fully opaque, because `rgb(_:)` always appends the alpha byte `FF`.
- **hex-accuracy**: Hex literals MUST decode to the intended color. The `hexAccuracy` test pins Dracula background `282a36`, Dracula foreground `f8f8f2`, Dracula ANSI index 5 `ff79c6`, and Solarized Light background `fdf6e3`.
- **legibility**: For every theme in `all`, the `SemanticPalette` derived from it MUST give `primaryText` a contrast ratio of at least 4.0 against `windowBackground`, `secondaryText` at least 2.5 against `windowBackground`, and `onAccentText` at least 3.0 against `accent`. The `legibility` test asserts these thresholds.
- **distinct-surface**: For every theme in `all`, the derived `surface` color MUST differ from the derived `windowBackground` color.

### Chrome overrides

- **chrome-override-roles**: Each hand-authored theme's `roleOverrides` MUST contain an entry for each of `surface`, `elevatedSurface`, `controlBackground`, `border` and `outline`, keyed by `ThemeRole.rawValue`. The `chromeOverrides` test asserts this.
- **chrome-override-only**: The hand-authored themes MUST set no role override other than those five, leaving text, accent and status roles to derive from the palette.
- **chrome-builder**: The private `chrome(surface:elevated:control:border:outline:)` helper MUST map its `surface` argument to the `surface` role, `elevated` to `elevatedSurface`, `control` to `controlBackground`, `border` to `border` and `outline` to `outline`.

### Hex parsing

- **hex-optional-hash**: The private `rgb(_:)` helper MUST accept a six-digit hex string with or without a leading `#`.
- **hex-invalid-traps**: `rgb(_:)` MUST halt with `preconditionFailure("Invalid built-in theme hex: <input>")` when `RGBAColor(hexString:)` rejects the string. The source documents this as fail-fast at first use, with constants validated by `BuiltInThemesTests`. `hexString` rejects anything that is not exactly eight hex digits once `FF` is appended, so a three-digit or seven-digit literal traps.

### Concurrency and persistence

- **immutable-statics**: Every theme and list is a `static let` value constructed once, lazily, on first access (Swift's initialization of static stored properties is thread-safe). The type has no mutable state, so concurrent reads from any thread need no coordination.
- **no-side-effects**: The type MUST NOT write files, call the network, spawn processes or post notifications. It reads and writes nothing; persistence of the active theme selection belongs to `ThemeStore` and `ThemeStorage`.

## Appearance

Not applicable — this is a static catalogue of color data, not a visual component.

## States

Not applicable — this is a static catalogue of color data, not a visual component.

## Accessibility

Not applicable — this is a static catalogue of color data, not a visual component. The legibility contract on its colors is a Behavioral Requirement (`legibility`).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| built-in-themes-001 | all-count, all-composition | Read `BuiltInThemes.all` | 36 themes; the first 15 are `handAuthored` in order, the remaining 21 are `webPortedNative` (`BuiltInThemesTests.count`) |
| built-in-themes-002 | unique-ids | Collect `all.map(\.id)` into a `Set` | Set size equals 36 (`BuiltInThemesTests.uniqueIDs`) |
| built-in-themes-003 | built-in-flag, ansi-count | Iterate `all` | Every theme has `isBuiltIn == true` and `hasValidPalette == true`, meaning 16 ANSI colors (`BuiltInThemesTests.validity`) |
| built-in-themes-004 | chrome-override-roles | Iterate `handAuthored`, read `roleOverrides` for the five chrome roles | No role is missing for any theme (`BuiltInThemesTests.chromeOverrides`) |
| built-in-themes-005 | default-id, default-resolves | `theme(withID: BuiltInThemes.defaultID)` | Returns the theme whose `name` is "Solarized Dark" (`BuiltInThemesTests.defaultResolves`) |
| built-in-themes-006 | lookup-miss | `theme(withID: "no-such-id")` | Returns `nil` |
| built-in-themes-007 | lookup-exact-match | `theme(withID: "a1b2c3d4-0001-4000-8000-000000000001")` (lower case) | Returns `nil` |
| built-in-themes-008 | lookup-hit | `theme(withID: "A1B2C3D4-0003-4000-8000-000000000003")` | Returns Dracula |
| built-in-themes-009 | hex-accuracy | Compare `dracula.background` with `RGBAColor(hexString: "#282A36FF")` | Equal (`BuiltInThemesTests.hexAccuracy`) |
| built-in-themes-010 | hex-accuracy, ansi-count | Compare `dracula.ansi[5]` with `#FF79C6FF` and `solarizedLight.background` with `#FDF6E3FF` | Both equal (`BuiltInThemesTests.hexAccuracy`) |
| built-in-themes-011 | legibility, distinct-surface | For each theme build `SemanticPalette(theme:)` and read contrast ratios | primaryText over windowBackground at least 4.0; secondaryText over windowBackground at least 2.5; onAccentText over accent at least 3.0; surface differs from windowBackground (`BuiltInThemesTests.legibility`) |
| built-in-themes-012 | hand-authored-order, hand-authored-appearance | Read `handAuthored.map(\.name)` and `.appearance` | First name Solarized Dark, last Gruvbox Light; 11 `.dark` and 4 `.light` |
| built-in-themes-013 | opaque-colors | Read `alpha` of `nord.foreground` and of every `nord.roleOverrides` value | Every alpha equals 1 |
| built-in-themes-014 | chrome-override-only | Read `Set(solarizedDark.roleOverrides.keys)` | Equals the five raw values `surface`, `elevatedSurface`, `controlBackground`, `border`, `outline` |
| built-in-themes-015 | chrome-builder | Read `solarizedDark.roleOverrides` for `border` and `outline` | `border` is `0e4452` and `outline` is `1d5b69`, both opaque |
| built-in-themes-016 | hex-optional-hash | Call `rgb("#839496")` and `rgb("839496")` (the helper is private, so assert through a theme constant built with each form in a test double) | Both return the same opaque color |
| built-in-themes-017 | hex-invalid-traps | Call `rgb("xyz")` | Halts with the message `Invalid built-in theme hex: xyz` (a crash, so a port asserts it through its equivalent of a death test) |
| built-in-themes-018 | attribution-present, stable-ids | Read `solarizedDark.attribution` and `.id` | Attribution is "Ethan Schoonover"; id is `A1B2C3D4-0001-4000-8000-000000000001` |

## Edge Cases

- **Unknown ID**: `theme(withID:)` with an ID matching no built-in MUST return `nil`, not trap or return a default. A caller that needs a fallback uses `defaultID` itself.
- **Empty ID**: `theme(withID: "")` MUST return `nil`, since no built-in has an empty `id`.
- **Case difference**: An ID differing only in letter case MUST NOT match, because comparison is exact string equality.
- **Duplicate IDs**: The source does not guard against two entries sharing an ID; `theme(withID:)` would return the first. Uniqueness is enforced only by the `uniqueIDs` test, so a duplicate is caught at test time, not at runtime.
- **Malformed hex literal**: A built-in constant that is not valid hex MUST trap on first access of the theme that contains it (fail-fast), as the `rgb(_:)` doc comment states. Because the themes are `static let`, the trap happens on first use of that constant or of `all`, not at launch.
- **Bright ANSI duplicates**: Several schemes repeat a normal color as its bright variant (Nord bright indices 9 to 13 repeat normal indices 1 to 5, Monokai Pro repeats cyan at indices 4, 6, 12 and 14). That is the data as authored and a port MUST copy it rather than invent distinct brights.
- **Mixed ANSI ordering**: Gruvbox Light places `fbf1c7` (its background tone) at ANSI index 0 and `3c3836` at index 15, the reverse of Solarized Dark's relationship; a port MUST NOT normalize the order.
- **Concurrent access**: Not applicable beyond `immutable-statics`: the values are immutable after lazy initialization, which Swift performs thread-safely, so concurrent readers need no lock.
- **Offline or disconnected**: Not applicable — the catalogue is compiled-in data with no network or file dependency.
- **Null input**: Not applicable — `theme(withID:)` takes a non-optional `String`; the only absent value is the optional return.
- **Boundary values**: The palette length is the only bounded input, and it is fixed at 16 by `ansi-count`; the catalogue size is fixed at 36 by `all-count`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `BuiltInThemes.defaultID` | `String` | `A1B2C3D4-0001-4000-8000-000000000001` | ID of the theme used when no selection is persisted (Solarized Dark) |
| `BuiltInThemes.all` | `[ColorTheme]` | 36 themes | Ordered catalogue; display order in theme pickers follows it |
| `BuiltInThemes.handAuthored` | `[ColorTheme]` | 15 themes | Internal subset with authentic chrome overrides |

The catalogue takes no environment variables, settings keys or injected dependencies. It depends on `ColorTheme`, `ThemeRole`, `RGBAColor` and, for the web-ported part, the two extension files named in the Overview. Each theme leaves `isImported` at its default `false` and `typography`, `terminal` and `project` at the `ColorTheme` initializer defaults (`.system`, `nil`, `nil`).

## Deep Linking

Not applicable: the source defines no URL scheme, route or link target; it is a static catalogue of color data.

## Localization

Not applicable: theme `name` and `attribution` values are proper nouns and credits written as hardcoded string literals (including the accented "Rosé Pine"), and the source has no string table or localized lookup. The Unicode character in "Rosé Pine" is stored as ordinary UTF-8 in the Swift source.

## Accessibility Options

Not applicable: the catalogue does not read Reduce Motion, Increase Contrast or Differentiate Without Color. Contrast is guaranteed by the derived roles in `SemanticPalette`, which the `legibility` requirement checks for every theme.

## Feature Flags

Not applicable: the source reads no flag; every theme in `all` is always present.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the catalogue holds public color values and credits, collects nothing, stores nothing and transmits nothing.

## Logging

Not applicable: the source makes no log call. The only diagnostic is the `preconditionFailure` message in `rgb(_:)`, which halts the process instead of logging.

## Platform Notes

- **SwiftUI**: Source platform. The code is in `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/BuiltInThemes.swift`, with `BuiltInThemes+Web.swift` and `BuiltInThemes+Native.swift` supplying the web-ported part and its native adjustments. Static `let` properties on a caseless enum give thread-safe lazy initialization for free. This file imports only `Foundation` and produces only value data; the conversion from `RGBAColor` to platform colors lives in the UI target (`SemanticPalette+NSColor.swift` on macOS and `SemanticPalette+UIColor.swift` on iOS under `SDK/SourcesUI`).
- **Compose**: Use a Kotlin `object` holding `val` lists of a data class with `Color(0xFF...)` fields (`Color` takes ARGB, so the alpha byte moves to the front). A `lazy` list matches the lazy static initialization; `require(hex.length == 6)` plays the role of the fail-fast `preconditionFailure`. Apply the chrome overrides in a `ColorScheme` or custom `CompositionLocal` rather than Material defaults.
- **React/Web**: Use a frozen module-level array of theme objects keyed by the same ID strings, and a `Map` for `theme(withID:)` to give constant-time lookup. Validate hex literals at module load with a thrown `Error`, since JavaScript has no precondition trap. Expose chrome roles as CSS custom properties.
- **AppKit / UIKit**: Convert `RGBAColor` to `NSColor` or `UIColor` with the sRGB initializer using the stored 0 to 1 components. The catalogue itself is identical to the SwiftUI use; only the color bridge differs.
- **WinUI 3**: Model a theme as a C# `record` with `Windows.UI.Color` (`Color.FromArgb(0xFF, r, g, b)`) fields, and hold the catalogue in a `static readonly IReadOnlyList<ColorTheme>`, which the CLR initializes once and thread-safely through a static constructor. Look up by ID with `FirstOrDefault(t => t.Id == id)` using `StringComparison.Ordinal` to keep the exact-match rule. Surface the chrome roles as `SolidColorBrush` entries in a `ResourceDictionary` merged at the application level, overriding `ThemeDictionaries` keys such as `LayerFillColorDefaultBrush` rather than editing control templates, and set `RequestedTheme` to `Dark` or `Light` from `appearance`. Replace the Swift `preconditionFailure` with an `ArgumentException` thrown from a static initializer, or a unit test over the constants; a static constructor failure surfaces as `TypeInitializationException` on first access, which matches the first-use trap. Persist the selected ID with `Windows.Storage.ApplicationData.Current.LocalSettings`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/BuiltInThemes.swift` | confirmed (1.0.1) |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |

## Design Decisions

**Decision**: Define each built-in theme once, here, and derive the terminal feature's profiles from this list.
**Rationale**: The doc comment calls this list the single source of truth, so a color edit cannot drift between the terminal and the rest of the app.
**Approved**: pending

**Decision**: Give the hand-authored themes explicit chrome overrides for surface, elevated surface, control background, border and outline instead of deriving them.
**Rationale**: The doc comment says the scheme's own published panel and line colors make panels and borders look authentic instead of muddy luminance blends. Text, accent and status roles still derive so `SemanticPalette` can guarantee their contrast.
**Approved**: pending

**Decision**: Keep `handAuthored` separate from `all`, and keep the web-ported themes off the chrome-override promise.
**Rationale**: The web-ported themes carry chat overrides from the web CSS and let chrome derive, so a test asserting chrome overrides must scope to the hand-authored set.
**Approved**: pending

**Decision**: Keep native-only adjustments in `BuiltInThemes+Native.swift`, applied over the generated web themes, rather than editing the generated file.
**Rationale**: The doc comment on `webPortedNative` says the web file is generated and must not be hand-edited, so a re-run of the generator cannot silently drop the adjustments.
**Approved**: pending

**Decision**: Make `rgb(_:)` trap on a malformed literal instead of returning an optional or a fallback color.
**Rationale**: The doc comment says built-in constants are validated by `BuiltInThemesTests` and a bad literal fails fast at first use, so a typo cannot ship as a silently wrong color. The cost is a crash for a bad constant; there is no recoverable path.
**Approved**: pending

**Decision**: Keep the stable, position-based ID scheme with its historical numbering, even where it differs from list order.
**Rationale**: The doc comment says the IDs are shared with the terminal feature's historical profile IDs so persisted active-theme selections survive upgrades; renumbering would orphan them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

The catalogue does one job: it holds color data and looks it up by ID, while persistence, palette derivation and display live in other types, so separation of concerns passes. `BuiltInThemesTests` covers the count, unique IDs, palette validity, chrome overrides, legibility, the default ID and hex accuracy, so unit-test coverage passes; it does not directly test `lookup-miss`, the case-sensitive match or the invalid-hex trap, which keeps the matching vectors in this recipe as the only specification of them. Error handling is partial because a malformed literal halts the process by design instead of returning an error, which is explicit and documented but not recoverable. The no-hardcoded-strings check is partial because theme names and attributions are English literals; they are proper nouns, but they are not externalized.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
