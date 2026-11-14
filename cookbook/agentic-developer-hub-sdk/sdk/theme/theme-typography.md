---
id: ccc0d121-4927-4a83-b0e5-337116edebc0
title: "ThemeTypography"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Theme typography model: text roles, theme-portable font weights and styles, per-role overrides with system defaults, a global size scale and its 0.5 to 4 clamp."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - typography
  - codable
  - logic
depends-on: []
related:
  - 932449c9-b57f-4e2c-992a-1e27584742b6
references: []
approved-by: ""
approved-date: ""
---

# ThemeTypography

## Overview

`ThemeTypography` is the typography half of a theme. It holds one `FontStyle` per `TextRole` plus a global `sizeScale` that multiplies every role's size at once. UI code reads fonts by role (`title`, `heading`, `body`, `caption`, `code`, `button`) the way it reads colors by `ThemeRole`, so a label's meaning survives a theme swap and a global size change.

The source file defines four public types and two clamp helpers: `TextRole` (enum), `FontWeight` (enum), `FontStyle` (struct) and `ThemeTypography` (struct, with `sizeScaleRange` and `clampedSizeScale(_:)`). It imports only `Foundation`; the source comment says `FontWeight` is bridged to `NSFont.Weight` in CoreMacOS so the Core model stays Foundation-only. The bridges to platform fonts live in separate files (the iOS bridge is `ThemeTypography+UIFont.swift`) and are not part of this contract. A `ColorTheme` carries a `ThemeTypography` as its `typography` property (see [ColorTheme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6)).

## Behavioral Requirements

Text roles

- **role-cases**: `TextRole` MUST have exactly six cases: `title`, `heading`, `body`, `caption`, `code` and `button`.
- **role-raw-value**: `TextRole` MUST be a `String`-backed enum whose raw value equals the case name (`"title"`, `"heading"`, `"body"`, `"caption"`, `"code"`, `"button"`).
- **role-meaning**: Each role MUST mean what its doc comment says: `title` large window or screen titles; `heading` section or group headers; `body` default body text; `caption` small secondary text; `code` monospaced text; `button` control labels.
- **role-conformances**: `TextRole` MUST be `CaseIterable` and `Sendable`.

Font weight

- **weight-cases**: `FontWeight` MUST have exactly nine cases in this order: `ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`, `heavy`, `black`.
- **weight-codable**: `FontWeight` MUST be `String`-backed, `Codable`, `CaseIterable` and `Sendable`, and its raw value MUST equal the case name.
- **weight-foundation-only**: `FontWeight` MUST NOT depend on any platform font type; the platform bridge is the caller's.

Font style

- **style-fields**: `FontStyle` MUST expose four mutable properties: `family` (optional `String`), `size` (`Double`), `weight` (`FontWeight`) and `monospaced` (`Bool`).
- **style-family-nil**: A `nil` `family` MUST mean the system font.
- **style-size-base**: `FontStyle.size` MUST be the base point size before the theme's `sizeScale` is applied.
- **style-monospaced**: `monospaced` set to true MUST mean the style resolves to a monospaced font (digits and glyphs fixed-width). The resolution itself belongs to the platform bridge.
- **style-init-defaults**: `FontStyle.init(family:size:weight:monospaced:)` MUST default `family` to nil, `weight` to `.regular` and `monospaced` to false; `size` is required.
- **style-conformances**: `FontStyle` MUST be `Codable`, `Equatable` and `Sendable`. Equality is the synthesized memberwise comparison.
- **style-no-size-validation**: `FontStyle` MUST NOT validate or clamp `size`; zero, negative and non-finite values are stored as given.

Typography value

- **typography-fields**: `ThemeTypography` MUST expose two mutable properties: `sizeScale` (`Double`) and `styles` (`[String: FontStyle]`).
- **typography-init-defaults**: `ThemeTypography.init(sizeScale:styles:)` MUST default `sizeScale` to 1.0 and `styles` to the empty dictionary.
- **typography-init-no-clamp**: `ThemeTypography.init` MUST NOT clamp `sizeScale`; a stored scale outside `sizeScaleRange` is kept as given. Clamping is applied by callers (`clamp-callers`).
- **styles-key**: `styles` MUST be keyed by `TextRole.rawValue`, so the dictionary round-trips through `Codable` and `UserDefaults` as a plain string-keyed object.
- **typography-conformances**: `ThemeTypography` MUST be `Codable`, `Equatable` and `Sendable`. Equality is the synthesized memberwise comparison of `sizeScale` and `styles`.
- **styles-unknown-key**: `styles` MAY hold a key that is not a `TextRole` raw value; the type neither rejects it nor reads it, because lookups are by `role.rawValue` only.

Style lookup

- **style-lookup-override**: `style(_:)` MUST return `styles[role.rawValue]` when an entry exists.
- **style-lookup-default**: `style(_:)` MUST return `defaultStyle(role)` when no entry exists for the role.
- **style-lookup-no-mutation**: `style(_:)` MUST NOT write the default into `styles`.
- **style-lookup-whole-entry**: `style(_:)` MUST return the override as one whole `FontStyle`; fields are not merged with the default. An override that sets only `size` therefore also resets `weight` and `monospaced` to the `FontStyle` initializer defaults (`.regular`, false), not to the role's default.

Effective size

- **size-effective**: `size(_:)` MUST return `style(role).size * sizeScale`.
- **size-stored-unchanged**: `size(_:)` MUST NOT change the stored `FontStyle.size` or `sizeScale`.
- **size-uses-stored-scale**: `size(_:)` MUST use the stored `sizeScale` as is, with no clamp, so a `sizeScale` of 0 yields an effective size of 0 for every role.

System defaults

- **default-style-table**: `defaultStyle(_:)` MUST return a style with `family` nil and these values:

| Role | size | weight | monospaced |
|------|------|--------|------------|
| `title` | 22 | `.semibold` | false |
| `heading` | 15 | `.semibold` | false |
| `body` | 13 | `.regular` | false |
| `caption` | 11 | `.regular` | false |
| `code` | 12 | `.regular` | true |
| `button` | 13 | `.medium` | false |

- **default-style-basis**: The default sizes mirror AppKit's standard metrics, so an uncustomized theme looks like the app does today (the source's doc comment).
- **system-constant**: `ThemeTypography.system` MUST equal `ThemeTypography()`: `sizeScale` 1.0, empty `styles`, every role at its system default.
- **default-covers-roles**: `defaultStyle(_:)` MUST return a style with `size` greater than 0 for every `TextRole` case.

Size scale limits

- **scale-range**: `ThemeTypography.sizeScaleRange` MUST be the closed range 0.5 to 4.
- **scale-range-rationale**: The lower bound exists because below 0.5 `size(_:)` collapses every role toward zero and takes any constraint built on an intrinsic size with it; the upper bound exists because above 4 the size exceeds what a layout that assumes a roughly system-sized label can hold (the doc comment).
- **clamp-function**: `clampedSizeScale(_:)` MUST return the value limited to `sizeScaleRange`: a value below 0.5 returns 0.5, a value above 4 returns 4, and a value inside the range is returned unchanged; this holds for finite input (`clamp-nan` covers non-finite input).
- **clamp-infinity**: `clampedSizeScale(_:)` MUST return `1.0` for negative and positive infinity alike, not the nearest bound, because the finite check runs before the limit.
- **clamp-nan**: `clampedSizeScale(_:)` MUST return `1.0`, the unscaled size, for a non-finite input (NaN or either infinity), because `min` and `max` would pass NaN straight through the limit. Covered by `clampNonFinite`.
- **clamp-callers**: The clamp MUST be applied by every path that sets a scale from outside the type: `SemanticPalette.scaled(by:)` (the reader's runtime "Text Size" control) and `ThemeStore.importJSON` (a theme file's declared `typography.sizeScale`). Both call `clampedSizeScale(_:)` so the two cannot drift onto different limits.
- **clamp-repair-not-refuse**: `ThemeStore.importJSON` repairs an out-of-range scale by clamping it rather than rejecting the file, because a bad scale leaves a theme mis-sized, not unusable (its doc comment).

Persistence and side effects

- **codable-synthesized**: `ThemeTypography`, `FontStyle` and `FontWeight` use synthesized `Codable`; `ThemeTypography` encodes as an object with keys `sizeScale` and `styles`, and `FontStyle` as an object with keys `family`, `size`, `weight` and `monospaced`.
- **decode-strict**: Decoding MUST fail with the decoder's own error when a required key is missing (`sizeScale`, `styles`, `size`, `weight`, `monospaced`) or a `weight` string is not one of the nine cases; the type has no custom decoder and substitutes no defaults. A nil `family` is omitted when encoding and decodes as nil when the key is absent.
- **no-side-effects**: Every operation in this contract MUST NOT perform I/O, logging, notification or persistence. Persistence is by the caller, through `Codable`.
- **concurrency**: All types MUST be value types conforming to `Sendable`; any thread MAY read a copy without synchronization. Mutation of a single instance is the caller's to serialize.

## Appearance

Not applicable — this is a typography data model, not a visual component. It carries font family, size, weight and monospaced flags; turning them into a rendered font happens in the platform bridges.

## States

Not applicable — this is a value type, not a visual component, and it has no runtime state machine. Its only mutation is assignment to its public properties.

## Accessibility

Not applicable — this is a typography data model, not a visual component. `sizeScale` is the mechanism hosts use to implement a user-controlled text size, but the type itself has no labels, focus or contrast logic.

## Conformance Test Vectors

Tests live in `ThemeTypographyTests` (Swift Testing suite `ThemeTypography`): `systemHasAllRoles`, `sizeScaleApplies`, `explicitStyleWins`, `codableRoundTrip`, `colorThemeCarriesTypography` and `clampNonFinite`. `clampNonFinite` also asserts `clampedSizeScale(9)` is 4 and `(0.1)` is 0.5. The suite has no test of `sizeScaleRange` itself; that vector and the in-range clamp rows derive from the source and from the call sites in `ThemeStore` and `SemanticPalette`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| typography-001 | default-covers-roles, system-constant | `ThemeTypography.system.style(role).size` for each `TextRole.allCases` (test `systemHasAllRoles`) | every size greater than 0 |
| typography-002 | default-style-table | `ThemeTypography.system.style(.code).monospaced` and `.style(.body).monospaced` (test `systemHasAllRoles`) | true and false |
| typography-003 | default-style-table | `system.style(.title).size` versus `system.style(.body).size` (test `systemHasAllRoles`) | 22 is greater than 13 |
| typography-004 | default-style-table | `defaultStyle(.heading)`, `.caption`, `.button` | (15, semibold), (11, regular), (13, medium), `family` nil, `monospaced` false |
| typography-005 | size-effective, size-stored-unchanged | system typography with `sizeScale = 1.5`; read `size(.body)` and `style(.body).size` (test `sizeScaleApplies`) | 19.5 and 13 |
| typography-006 | style-lookup-override, style-lookup-default | set `styles["body"]` to `FontStyle(family: "Menlo", size: 17, weight: .bold, monospaced: true)` (test `explicitStyleWins`) | `style(.body)` has family `Menlo`, size 17, weight `.bold`; `style(.title).size` is 22 |
| typography-007 | style-lookup-no-mutation | call `style(.body)` on `ThemeTypography()` | `styles` is still empty |
| typography-008 | style-lookup-whole-entry | `styles["body"] = FontStyle(size: 20)`; read `style(.body)` | size 20, weight `.regular`, `monospaced` false, family nil; role default is not merged |
| typography-009 | codable-synthesized, styles-key, typography-conformances | `ThemeTypography(sizeScale: 1.25)` with `styles["title"] = FontStyle(family: "Avenir Next", size: 24, weight: .heavy)`; encode then decode (test `codableRoundTrip`) | decoded equals the original and `size(.title)` is 30 |
| typography-010 | typography-init-defaults, system-constant | `ThemeTypography()` and `ThemeTypography.system` | equal; `sizeScale` 1.0, `styles` empty |
| typography-011 | style-init-defaults | `FontStyle(size: 14)` | family nil, size 14, weight `.regular`, `monospaced` false |
| typography-012 | scale-range | `ThemeTypography.sizeScaleRange` | lower bound 0.5, upper bound 4 |
| typography-013 | clamp-function | `clampedSizeScale(0)`, `(0.1)`, `(0.5)`, `(1.0667)`, `(4)`, `(9)` | 0.5, 0.5, 0.5, 1.0667, 4, 4 |
| typography-014 | clamp-infinity | `clampedSizeScale(-.infinity)` and `(.infinity)` (test `clampNonFinite`) | 1.0 and 1.0 |
| typography-015 | clamp-callers, clamp-repair-not-refuse | `ThemeStore.importJSON` of a theme file declaring `"sizeScale": 0` with a valid palette | the imported theme's `typography.sizeScale` is 0.5; no error |
| typography-016 | clamp-callers | `SemanticPalette.scaled(by: 100)` | behaves as `scaled(by: 4)` |
| typography-017 | typography-init-no-clamp, size-uses-stored-scale | `ThemeTypography(sizeScale: 0).size(.body)` | 0 |
| typography-018 | decode-strict | decode `{"sizeScale": 1, "styles": {"body": {"size": 13, "weight": "plush", "monospaced": false}}}` | throws a decoding error; no default weight is substituted |
| typography-019 | decode-strict | decode `{"sizeScale": 1}` | throws `keyNotFound` for `styles` |
| typography-020 | role-cases, role-raw-value | `TextRole.allCases.map(\.rawValue)` | `["title", "heading", "body", "caption", "code", "button"]` |
| typography-021 | weight-cases | `FontWeight.allCases.count` and first and last case | 9; `ultraLight` and `black` |
| typography-022 | clamp-nan | `clampedSizeScale(.nan)`, `(.infinity)`, `(-.infinity)` | 1.0 for each |
| typography-023 | styles-unknown-key | `styles["footnote"] = FontStyle(size: 9)`; read every role | every role resolves as before; the unknown key is kept and not read |
| typography-024 | style-no-size-validation | `FontStyle(size: -3).size` and `ThemeTypography(styles: ["body": FontStyle(size: 0)]).size(.body)` | -3 and 0 |

## Edge Cases

- **Empty `styles`**: every role resolves to `defaultStyle(_:)`; the empty `ThemeTypography()` reproduces the system-font look (`system-constant`). MUST.
- **Override for one role**: only that role changes; other roles keep their defaults (`explicitStyleWins`). MUST.
- **Partial override**: an override replaces the whole style, so omitted fields take the `FontStyle` initializer defaults rather than the role default. A `code` override that omits `monospaced` is not monospaced. MUST (to match the source); see `style-lookup-whole-entry`.
- **Boundary scale values**: 0.5 and 4 are inside `sizeScaleRange` and pass the clamp unchanged. MUST.
- **Scale outside the range**: the clamp returns the nearest bound; the stored `sizeScale` inside the type is never clamped on its own, so a value set directly on the property or through `init` stays out of range until a caller clamps it. MUST.
- **Zero or negative scale**: `size(_:)` returns 0 or a negative size for a stored scale of 0 or below; only the callers listed in `clamp-callers` prevent this. MUST (to match the source).
- **Non-finite scale**: NaN and both infinities clamp to 1.0, the unscaled size (`clamp-nan`). MUST.
- **Non-finite or non-positive style size**: `FontStyle.size` is unvalidated, so the model carries it as given. The platform bridge decides what to do with it. MUST (to match the source).
- **Imported theme with a bad scale**: repaired by clamping, not refused (`clamp-repair-not-refuse`). MUST.
- **Malformed JSON**: an unknown `weight` string or a missing required key makes decoding throw the decoder's own error; the type does not fall back to a default. MUST.
- **Unknown `styles` key**: kept in the dictionary, never read by `style(_:)`. MAY.
- **Concurrent access**: not applicable beyond `Sendable`; each copy is an independent value, so concurrent reads cannot race.
- **Offline or disconnected state**: not applicable; the types perform no network or file access.
- **Cancellation and timeouts**: not applicable; every operation is synchronous and bounded.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sizeScale` | `Double` | `1.0` | Global multiplier on every role's base size; the theme designer's scale (for example a typeface that draws small for its point size) |
| `styles` | `[String: FontStyle]` | `[:]` | Per-role overrides keyed by `TextRole.rawValue`; absent roles use `defaultStyle(_:)` |
| `FontStyle.family` | `String?` | `nil` | Font family name; `nil` is the system font |
| `FontStyle.size` | `Double` | required | Base point size before `sizeScale` |
| `FontStyle.weight` | `FontWeight` | `.regular` | Font weight |
| `FontStyle.monospaced` | `Bool` | `false` | Resolve to a monospaced font |
| `sizeScaleRange` | `ClosedRange<Double>` | `0.5...4` | Bounds a scale from outside the type may take |

The type reads no environment variables or settings keys and takes no injected dependencies.

## Deep Linking

Not applicable: the types are value types with no screens or URL routes.

## Localization

Not applicable: the source defines no user-facing strings. The `TextRole` and `FontWeight` raw values are persistence keys, not display text.

## Accessibility Options

Not applicable: the types hold font data and do not respond to Reduce Motion, Increase Contrast or Differentiate Without Color. The `sizeScale` multiplier is how a host's text-size control reaches the fonts, but the type has no rendering code.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the source collects, stores and transmits nothing. Fonts and sizes are theme data that the caller persists, through `Codable`, wherever it keeps the theme.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ThemeTypography.swift`, imports only `Foundation`, and compiles for macOS and iOS. A SwiftUI view builds `Font.system(size: typography.size(role), weight: ...)` from `size(_:)` and a `FontWeight` to `Font.Weight` switch, uses `.monospaced()` (or `Font.custom` with `family`) when `monospaced` or `family` is set, and keeps that bridge in the UI layer, not in this file.
- **Compose**: Port `TextRole` as an `enum class`, `FontStyle` as a `data class`, and the bridge as `TextStyle(fontSize = (size * sizeScale).sp, fontWeight = FontWeight(...), fontFamily = ...)`. Map the nine weights to Compose's numeric weights (100 to 900); use `FontFamily.Monospace` for `monospaced`. Compose has no AppKit default metrics, so keep the table of defaults from this recipe. `coerceIn(0.5f, 4f)` passes NaN through, so check `isFinite()` first and return 1f, as the source does.
- **React/Web**: Port as TypeScript string unions and plain readonly objects, with `styles` as `Record<string, FontStyle>` (already string-keyed, so `JSON.stringify` and `JSON.parse` give the same shape). Resolve to CSS with `font-size: calc(...)` or computed `px`, `font-weight` 100 to 900, `font-family` (adding `ui-monospace` or `monospace` when `monospaced`) and `font-variant-numeric: tabular-nums` if fixed-width digits are wanted. `Math.min(Math.max(v, 0.5), 4)` passes NaN through, so guard with `Number.isFinite(v) ? ... : 1` to match the source.
- **AppKit / UIKit**: The macOS bridge is `ThemeTypography+NSFont.swift` under `SDK/SourcesUI/macOS/Theme/` (`FontWeight` to `NSFont.Weight`, then `NSFont.systemFont(ofSize:weight:)`, `NSFont.monospacedSystemFont(ofSize:weight:)` or `NSFont(name:size:)` for a family); the iOS bridge is `ThemeTypography+UIFont.swift` under `SDK/SourcesUI/iOS/Theme/` (`UIFont.systemFont(ofSize:weight:)`, `UIFont.monospacedSystemFont(ofSize:weight:)`, `UIFont(name:size:)`). Feed the bridge `size(role)` so the scale is applied once.
- **WinUI 3**: Make `TextRole` and `FontWeightName` `enum`s serialized by name with `JsonStringEnumConverter` (camelCase naming policy to keep `ultraLight`), and `FontStyle` and `ThemeTypography` immutable `record` types (a `record` with `init` setters plus `with` expressions mirrors Swift's value-copy mutation). Use `Dictionary<string, FontStyle>` for `styles` with `System.Text.Json` (string keys serialize as an object). Apply it to a `TextBlock` or `Button` by setting `FontSize` to `size * sizeScale`, `FontFamily` to `new FontFamily(family ?? "Segoe UI Variable")` (or `"Cascadia Mono"` or `"Consolas"` when `monospaced`), and `FontWeight` from `Windows.UI.Text.FontWeights` (`Thin`, `Light`, `Normal`, `Medium`, `SemiBold`, `Bold`, `ExtraBold`, `Black`; WinUI has no `ultraLight` constant, so `new FontWeight { Weight = 100 }` or `ExtraLight` at 200). Expose a role as a named `Style` resource in `ResourceDictionary` (`Setter Property="FontSize"`) or write the values into the XAML type ramp (`TitleTextBlockStyle`, `SubtitleTextBlockStyle`, `BodyTextBlockStyle`, `CaptionTextBlockStyle`) when matching the system look. Clamp with `double.IsFinite(v) ? Math.Clamp(v, 0.5, 4) : 1.0`, because `Math.Clamp` alone passes NaN through and the source returns 1.0 for any non-finite value. WinUI's default sizes are 14 for body, 12 for caption and 28 for title, not this table, so keep the table. A "Text Size" slider binds through `INotifyPropertyChanged` to a view-model that re-applies `size * sizeScale`; the model itself needs no change notification.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ThemeTypography.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Fonts are read by role (`TextRole`), not by name or size, and each role resolves to a `FontStyle`.
**Rationale**: The source says a label's meaning survives a theme swap and a global size change when UI reads fonts by role, the same way it reads colors by `ThemeRole`.
**Approved**: pending

**Decision**: `styles` is a `[String: FontStyle]` keyed by `TextRole.rawValue` instead of a `[TextRole: FontStyle]`.
**Rationale**: The source says this mirrors `ColorTheme.roleOverrides` and round-trips cleanly through `Codable` and `UserDefaults`; a string key encodes as a JSON object, an enum key as an array. The cost is that a stray key is accepted silently (`styles-unknown-key`).
**Approved**: pending

**Decision**: A role missing from `styles` falls back to `defaultStyle(_:)`, and an override replaces the whole `FontStyle`.
**Rationale**: The source says the empty `ThemeTypography()` reproduces the app's current system-font look exactly. Replacement is the simplest lookup (`styles[rawValue] ?? default`); the consequence is that a partial override does not inherit the role's default weight or monospacing.
**Approved**: pending

**Decision**: `sizeScale` is a global multiplier applied at read time in `size(_:)`, and the stored `FontStyle.size` is never changed.
**Rationale**: The source says a user can make the whole app larger or smaller without editing each role. The theme's `sizeScale` is the designer's (for example 1.0667 for `old-school-terminal`, because VT323 draws small for its point size), while the reader's "Text Size" factor is separate, applied in `SemanticPalette.scaled(by:)`, so it survives a theme change.
**Approved**: pending

**Decision**: The 0.5 to 4 clamp is a shared static (`sizeScaleRange`, `clampedSizeScale(_:)`) applied by callers and not by `init` or `size(_:)`.
**Rationale**: The source says it is the one place both callers enforce the limit so they cannot drift. It is not enforced in `init` because a decoded or hand-built value is the caller's to repair; `ThemeStore.importJSON` repairs rather than refuses since a bad scale leaves the theme mis-sized, not unusable. The consequence is that a `ThemeTypography` built directly can hold any scale.
**Approved**: pending

**Decision**: `defaultStyle(_:)` uses AppKit's standard metrics (22, 15, 13, 11, 12 monospaced, 13 medium).
**Rationale**: The source says an uncustomized theme should look like the app does today. A port to another platform copies the numbers for parity but may keep its own native metrics when native look is wanted.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | accessibility |

The type is a Foundation-only value model with the platform font bridges kept in separate files, so separation of concerns passes. Unit-test coverage passes: `ThemeTypographyTests` covers defaults, scale, overrides, the `Codable` round trip and `clampedSizeScale(_:)` including non-finite input (`clampNonFinite`). Explicit error handling is partial because decoding failures surface as the decoder's own errors with no defaults, while the clamp maps non-finite input to 1.0. Input sanitization is partial: an imported theme's scale is clamped, but `FontStyle.size` and a directly constructed `sizeScale` are not validated. Dynamic type support is partial: `sizeScale` gives a multiplier a host can drive from a text-size control, but the type has no link to the platform's own Dynamic Type setting.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Non-finite size scale becomes 1.0; a delete that matches nothing skips the write; claims verified against source |
