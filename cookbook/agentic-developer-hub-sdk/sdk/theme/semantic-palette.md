---
id: 1f80f43d-5aa4-42cf-bc3e-fb742662b615
title: "SemanticPalette"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "Resolves 40 semantic color roles from a ColorTheme by override or derivation from its terminal palette, plus chart hues, text scale and project colors."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - color
  - palette
  - logic
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# SemanticPalette

## Overview

`ThemeRole` is a closed list of 40 semantic color roles (window and surface backgrounds, five text emphases, status accents, lines, selection and caret, and an 18-role chat group). UI code reads a color by role and never by raw ANSI slot, so a control's meaning survives a theme swap. `SemanticPalette` is the value that turns a `ColorTheme` into a concrete `RGBAColor` for every role. For each role an explicit entry in `ColorTheme.roleOverrides` wins; otherwise the color is derived from the theme's background, foreground, selection, cursor and 16-color ANSI table, so a plain terminal scheme can drive app-wide chrome.

The same file also carries three things that read the resolved palette: two ordered hue lists for charts (`chartSeriesColors`, `identitySeriesColors`), a reader text-size multiplier (`size(_:)`, `scaled(by:)`), and three colors for the project window (`projectPaneBackdrop`, `projectPaneOutline`, `projectActivePaneOutline`). The contrast and blend math it relies on lives in `RGBAColor+Theme.swift` and is out of scope here, except where the derivation constants below name it.

## Behavioral Requirements

Role set

- **role-enum**: `ThemeRole` MUST be a `String`-backed, `CaseIterable`, `Sendable` enumeration whose raw value is the case name, because the raw value is the key into `ColorTheme.roleOverrides`.
- **role-groups**: `ThemeRole` MUST define these roles, in this order. Backgrounds: `windowBackground`, `surface`, `elevatedSurface`, `controlBackground`, `card`. Text: `primaryText`, `secondaryText`, `tertiaryText`, `placeholderText`, `onAccentText`. Status: `accent`, `success`, `warning`, `danger`, `info`. Lines: `border`, `outline`, `divider`. Selection and caret: `selection`, `selectionText`, `selectionEdge`, `cursor`. Chat: `personaBubble`, `personaBubbleBorder`, `personaText`, `personaName`, `userBubble`, `userBubbleBorder`, `userText`, `userName`, `chatSurface`, `chatInputBackground`, `chatInputBorder`, `chatInputFocus`, `sendButton`, `sendButtonText`, `sendButtonHover`, `timestampText`, `thinkingDoneText`, `thinkingIdleText`.

Construction and lookup

- **struct-shape**: `SemanticPalette` MUST be a public `Equatable`, `Sendable` struct holding the `ColorTheme` it was built from in `theme`.
- **resolve-once**: `init(theme:)` MUST resolve every case in `ThemeRole.allCases` exactly once and store the results, so later `color(_:)` calls are dictionary reads. The source comment gives the reason: resolving the dimmed text roles runs an iterative contrast loop that is too costly to repeat in draw paths.
- **resolution-order**: Resolving a role MUST return the `ColorTheme.roleOverrides` entry keyed by the role's raw value when one exists, and the derived color otherwise.
- **color-lookup**: `color(_:)` MUST return the stored resolved color for the role. If the stored map has no entry it MUST resolve the role on demand with the same override-or-derive rule. With the shipped initializers that fallback is never reached.
- **color-accessors**: Each of the 40 roles MUST also be readable as a same-named computed property (`accent`, `surface`, `userBubble`, and so on) that returns `color(<role>)`.
- **declares**: `declares(_:)` MUST return true exactly when `theme.roleOverrides` has an entry for the role's raw value, and false for every role that is merely derived. It reads only the overrides, never the resolved colors.
- **declares-purpose**: `declares(_:)` exists so a caller can tell a theme that wants an element (a bubble outline) from a theme that merely derives to some opaque color; the source comment says every role derives to an opaque color, so visibility cannot answer that question.
- **derived-ignores-overrides**: `derived(_:)` MUST return the default palette-derived color for a role and MUST ignore `roleOverrides`.
- **chains-use-derived-parents**: A derived role that is defined in terms of another role MUST be computed from that role's derived value, not its overridden value. This applies to `card` (from `elevatedSurface`), `onAccentText`, `personaName`, `userBubble`, `userBubbleBorder`, `chatInputFocus`, `sendButton`, `sendButtonText` and `sendButtonHover` (all from `accent`). A theme that overrides `accent` therefore does not change those derived roles unless it overrides them too.

Derivation table

Let `bg` be `theme.background` and `fg` be `theme.foreground`. `blend(f, of: x)` is `bg.blended(withFraction: f, of: x)`. `dim(by, min)` is `fg.dimmed(towards: bg, by: by, minContrast: min)`. `ansi(n)` is `theme.ansiColor(at: n)`, falling back to `fg` when the slot is absent.

- **derive-backgrounds**: With no override, `windowBackground` MUST be `bg`; `surface` MUST be `blend(0.06, of: fg)`; `elevatedSurface` MUST be `blend(0.12, of: fg)`; `controlBackground` MUST be `blend(0.09, of: fg)`; `card` MUST be the derived `elevatedSurface`.
- **derive-card-own-role**: `card` MUST remain its own role even though it derives to `elevatedSurface`, so a theme can set cards apart from pane title bars and footers, which stay on `elevatedSurface` (source comment on `card`).
- **derive-text**: With no override, `primaryText` MUST be `fg`; `secondaryText` MUST be `dim(by: 0.32, min: 3.0)`; `tertiaryText` MUST be `dim(by: 0.55, min: 2.0)`; `placeholderText` MUST be `dim(by: 0.68, min: 1.6)`.
- **derive-on-accent**: With no override, `onAccentText` MUST be the best-contrast opaque black or white for the derived `accent`.
- **derive-status**: With no override, `accent` MUST be `ansi(4)`, `success` `ansi(2)`, `warning` `ansi(3)`, `danger` `ansi(1)` and `info` `ansi(6)`; each MUST fall back to `fg` when the theme has no color at that slot.
- **derive-lines**: With no override, `border` MUST be `blend(0.18, of: fg)`, `outline` `blend(0.30, of: fg)` and `divider` `blend(0.10, of: fg)`.
- **derive-selection**: With no override, `selection` MUST be `theme.selection`; `selectionText` MUST be the best-contrast opaque black or white for `theme.selection`; `cursor` MUST be `theme.cursor`.
- **derive-selection-edge**: With no override, `selectionEdge` MUST be the clear color, so only a theme that declares it draws a selection line (source comment: "a theme opts in by declaring it").
- **derive-persona**: With no override, `personaBubble` MUST be `blend(0.08, of: fg)`; `personaBubbleBorder` `blend(0.16, of: fg)`; `personaText` `fg`; `personaName` the derived `accent`.
- **derive-user**: With no override, `userBubble` MUST be `bg` blended 0.18 toward the derived `accent`; `userBubbleBorder` `bg` blended 0.34 toward the derived `accent`; `userText` `fg`; `userName` `dim(by: 0.32, min: 3.0)`.
- **derive-composer**: With no override, `chatSurface` MUST be `bg`; `chatInputBackground` `blend(0.09, of: fg)`; `chatInputBorder` `blend(0.18, of: fg)`; `chatInputFocus` the derived `accent`.
- **derive-send-button**: With no override, `sendButton` MUST be the derived `accent`; `sendButtonText` the best-contrast opaque black or white for the derived `accent`; `sendButtonHover` the derived `accent` blended 0.18 toward `fg`.
- **derive-timestamp**: With no override, `timestampText` MUST be `dim(by: 0.55, min: 2.0)`.
- **derive-thinking-done**: With no override, `thinkingDoneText` MUST be `fg` fully desaturated, then dimmed toward `bg` by 0.55 with a minimum contrast of 2.0. The source comment explains that the grey is the meaning (a stopped turn is no longer the live thing) and that a fixed mid-grey such as web's `#8a8a8a` washes out on a light theme, so the value is derived rather than transcribed.
- **derive-thinking-idle**: With no override, `thinkingIdleText` MUST be `fg` fully desaturated, then dimmed toward `bg` by 0.25 with a minimum contrast of 3.0. It is deliberately lighter-handed than `thinkingDoneText` and deliberately not in the theme's hue, so an idle line never reads like a turn that has not ended.
- **thinking-roles-distinct**: `thinkingDoneText`, `thinkingIdleText` and `timestampText` MUST stay three separate roles; the source comments record that themes set them apart (for example phosphor-green themes set the done line green while leaving the timestamp dim).

Chart colors

- **chart-series**: `chartSeriesColors` MUST list `accent`, `success`, `info`, `warning`, `danger` (resolved colors) followed by ANSI slots 9, 10, 11, 12, 13 and 14 that exist, and keep only entries whose contrast ratio against the resolved `surface` is at least 1.5.
- **chart-series-nonempty**: `chartSeriesColors` MUST return the five semantic colors unfiltered when the contrast filter removes every entry, so the list is never empty.
- **chart-excludes-neutrals**: `chartSeriesColors` MUST NOT draw from ANSI slots 0, 7, 8 or 15, which the source comment says sit near the background on most themes.
- **identity-series**: `identitySeriesColors` MUST visit ANSI slots 5, 6, 13 and 14 in that order and keep a slot's color only if it exists, has a contrast ratio against the resolved `surface` of at least 1.5, is not equal to any of the resolved `accent`, `success`, `warning` or `danger`, and is not already in the list.
- **identity-excludes-state**: `identitySeriesColors` MUST drop, not merely demote, a candidate equal to a state color, so an identity color can never be read as a state. `info` is intentionally not in the excluded set.
- **identity-fallback**: `identitySeriesColors` MUST return `chartSeriesColors` when no candidate survives; the source comment says two members in the same color beat two members in no color.

Reader text scale

- **size-formula**: `size(_:)` MUST return `theme.typography.size(role)` multiplied by the palette's private reader scale.
- **reader-scale-default**: A palette built with `init(theme:)` MUST have a reader scale of 1.
- **scaled-clamp**: `scaled(by:)` MUST clamp `factor` with `ThemeTypography.clampedSizeScale` before using it; a non-finite factor becomes 1.0. `ThemeTypography.sizeScaleRange` is 0.5 through 4, the same bound `ThemeStore` applies to an imported theme's own scale.
- **scaled-identity**: `scaled(by:)` MUST return the receiver unchanged when the clamped factor equals 1.
- **scaled-compounds**: `scaled(by:)` MUST return a new palette with the same `theme` and the same resolved colors and with reader scale multiplied by the clamped factor. Scaling a scaled palette therefore compounds.
- **scaled-keeps-theme**: `scaled(by:)` MUST NOT write the factor into `theme`, so the reader's "Text Size" choice survives a theme change and the designer's `sizeScale` stays a property of the typeface.
- **scaled-no-recolor**: `scaled(by:)` MUST NOT recompute colors; it reuses the stored map.

Project window colors

- **project-pane-backdrop**: `projectPaneBackdrop` MUST return `theme.project?.paneBackdrop` when set, otherwise `elevatedSurface`.
- **project-pane-outline**: `projectPaneOutline` MUST return `theme.project?.paneOutline` when set, otherwise `border`.
- **project-active-pane-outline**: `projectActivePaneOutline` MUST return `accent` and MUST NOT consult any theme override of its own. The source comment says a theme that recolors `paneOutline` restyles the frame while the active pane still stands out.

Concurrency, persistence and side effects

- **concurrency**: `SemanticPalette` is `Sendable` and all stored properties are immutable `let` values, so a palette MAY be read from any thread and every method is a pure function of its inputs.
- **no-side-effects**: Construction and every accessor MUST NOT perform file, network, process or notification work and MUST NOT log.
- **equatable-scope**: Equality MUST compare `theme`, the resolved map and the reader scale. The resolved map is derived purely from `theme`, so it never breaks equality (source comment).
- **error-surface**: No operation throws or returns an optional. A missing ANSI slot falls back to `fg`, a missing override falls back to derivation, and an out-of-range scale is clamped.

## Appearance

Not applicable — this is a color-resolution engine, not a visual component; it draws nothing and only returns `RGBAColor` values.

## States

Not applicable — this is an immutable value, not a visual component. It has no runtime state machine; the only variation is the reader scale, which `scaled(by:)` bakes into a new value.

## Accessibility

Not applicable — this is a color-resolution engine, not a visual component. The legibility floors it applies (minimum contrast 3.0 for `secondaryText` and `userName`, 2.0 for `tertiaryText` and `timestampText`, 1.6 for `placeholderText`) are recorded under Behavioral Requirements.

## Conformance Test Vectors

Tests beside the source are `SemanticPaletteTests`, `SemanticPaletteRolesTests`, `SemanticPaletteScaleTests`, `ChatRoleDerivationTests` and `IdleStatusInkTests` in `SDK/Tests/AgenticDeveloperHubSDKTests/Theme/`. The `declares` assertions are in `VSCodeThemeImporterTests` and `SyntaxRoleOverridesTests`, and palette-fed editor colors are in `SemanticPaletteEditorThemeTests`. Vectors name the test where one exists; the rest follow from the source's formulas, and opaque `bg` black and `fg` white make the blends easy to check by hand.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| semantic-palette-001 | declares, derived-ignores-overrides | Theme whose `roleOverrides` holds only `accent`; ask `declares` for every `ThemeRole` (`SyntaxRoleOverridesTests`, `VSCodeThemeImporterTests`) | True for `accent` only; false for all 39 others |
| semantic-palette-002 | declares | Theme with six overrides (`surface`, `elevatedSurface`, `controlBackground`, `secondaryText`, `placeholderText`, `outline`) (`VSCodeThemeImporterTests`) | `declares` is true for those six and false for `windowBackground`, `primaryText`, `selection`, `accent`, `danger`, `border`, `warning` |
| semantic-palette-003 | resolution-order | Tests `explicit role overrides win over derived colors` (`SemanticPaletteTests`) and `new-role overrides win over derivation` (`SemanticPaletteRolesTests`). Theme with no overrides and a theme with `surface` overridden to `#111111FF` | First: `surface` is the 6% blend toward foreground; second: `color(.surface)` is `#111111FF` while `derived(.surface)` is still the 6% blend |
| semantic-palette-004 | derive-status | Theme with `ansi` set to an empty array (`SemanticPaletteEditorThemeTests`, `shortPalette`) | `accent`, `success`, `warning`, `danger`, `info` all equal the theme foreground, and the editor theme built from the palette uses those semantic colors |
| semantic-palette-005 | derive-backgrounds, derive-lines | `bg` is opaque black, `fg` is opaque white | `windowBackground` black; `surface` grey 0.06; `elevatedSurface` 0.12; `controlBackground` 0.09; `divider` 0.10; `border` 0.18; `outline` 0.30 (all opaque) |
| semantic-palette-006 | derive-selection-edge | Any theme with no `selectionEdge` override | `color(.selectionEdge)` is the clear color (alpha 0) |
| semantic-palette-007 | chains-use-derived-parents | Theme overriding only `accent` to red | `accent` is red; `personaName`, `sendButton` and `chatInputFocus` are still the derived accent (ANSI slot 4), not red |
| semantic-palette-008 | derive-card-own-role, chains-use-derived-parents | Theme overriding `elevatedSurface` only | `card` still equals the derived `elevatedSurface`, not the override |
| semantic-palette-009 | derive-thinking-idle, derive-thinking-done | Tests `the idle ink is greyer than the theme's own foreground`, `the idle ink and the settled ink are different colours` and `a saturated ink settles to a line with none of its colour left` (`IdleStatusInkTests`): phosphor green `#33ff66` on `#050805` | Both thinking roles have equal red, green and blue (grey); `thinkingDoneText` is dimmer than `thinkingIdleText` |
| semantic-palette-010 | chart-series | Test `chartSeriesColors are non-empty and all contrast against the surface` (`SemanticPaletteTests`) on Dracula; the ordering comes from the source. Theme where the five semantic colors and ANSI 9 to 14 are all visible against `surface` | List starts with the five semantic colors in the order accent, success, info, warning, danger, followed by the bright hues |
| semantic-palette-011 | chart-series-nonempty | Theme whose five semantic colors and bright hues all equal `surface` | `chartSeriesColors` returns the five semantic colors, not an empty list |
| semantic-palette-012 | identity-excludes-state | Test `identitySeriesColors tell members apart without claiming a state` (`SemanticPaletteTests`) on Dracula asserts no entry equals `accent`, `success`, `warning` or `danger`, every entry has contrast at least 1.5 against `surface`, and no duplicates. Theme whose ANSI 5 equals its `accent` and whose ANSI 6, 13 and 14 are distinct and visible | `identitySeriesColors` omits slot 5 and lists slots 6, 13, 14 |
| semantic-palette-013 | identity-fallback | Test `identitySeriesColors fall back rather than come back empty` (`SemanticPaletteTests`): ANSI slots 5, 6, 13 and 14 all equal to the background | `identitySeriesColors` equals `chartSeriesColors` |
| semantic-palette-014 | scaled-clamp, scaled-compounds, size-formula | Tests `a factor arriving from a slider is clamped at both ends` and `the reader's factor multiplies the theme's own scale rather than replacing it` (`SemanticPaletteScaleTests`). Palette with `sizeScale` 1.0 and a text role of 10 points; apply `scaled(by: 2)` then `scaled(by: 2)` | `size(role)` is 20 after one call and 40 after two; `scaled(by: 100)` on a fresh palette gives 40 (clamped to 4) and `scaled(by: 0)` gives 5 (clamped to 0.5) |
| semantic-palette-015 | scaled-identity | Test `a factor of one is the palette itself` (`SemanticPaletteScaleTests`): `palette.scaled(by: 1)` | Equal to `palette` |
| semantic-palette-016 | scaled-keeps-theme, scaled-no-recolor | Test `scaling changes type only, never colour` (`SemanticPaletteScaleTests`) asserts every `color(_:)` is unchanged; `palette.scaled(by: 2).theme` | Equal to `palette.theme`; every `color(_:)` is unchanged |
| semantic-palette-017 | project-pane-backdrop, project-pane-outline | Theme with `project` nil, then a theme whose `project` sets `paneBackdrop` and `paneOutline` (`ComposableTabsPaneChromeTests` reads `projectPaneBackdrop`) | First: `elevatedSurface` and `border`; second: the two declared colors |
| semantic-palette-018 | project-active-pane-outline | Any theme | `projectActivePaneOutline` equals `accent` |
| semantic-palette-019 | derive-text, derive-on-accent, derive-selection | Tests `secondary/tertiary text meet legibility floors but stay dimmer than primary` and `onAccentText and selectionText are readable on their fills` (`SemanticPaletteRolesTests`) | `secondaryText` contrast at least 3.0 and `tertiaryText` at least 2.0 against the window background, each no higher than the one above; `onAccentText` and `selectionText` contrast at least 4.5 on their fills |
| semantic-palette-020 | derive-persona, derive-user, derive-send-button | Test `chat text contrasts against its own bubble in every built-in theme` (`ChatRoleDerivationTests`) | `personaText`, `userText` and `sendButtonText` each have contrast at least 3.0 against their composited fill in every built-in theme |
## Edge Cases

- **Missing ANSI slot**: `ColorTheme.ansiColor(at:)` returns nil for a slot beyond the theme's `ansi` array, so the status roles fall back to `fg`. MUST.
- **Empty ANSI table**: all chart and identity candidates from ANSI slots vanish; `chartSeriesColors` still returns the five semantic colors and `identitySeriesColors` falls back to them. MUST.
- **Low-contrast imported scheme**: `dimmed` shrinks its blend in steps of 0.05 until the minimum contrast holds; if no step reaches it, the result is `fg` unchanged. MUST.
- **Overridden parent role**: an override on `accent` or `elevatedSurface` does not flow into the roles derived from them; see `chains-use-derived-parents`. MUST (to match the source).
- **Translucent override**: an override such as a 40%-alpha color is returned as stored; resolution never composites it. The source gives no step that does. MUST.
- **Scale boundary**: `scaled(by:)` at 0.5 and 4 are accepted unchanged and anything outside is clamped; a factor of exactly 1 returns the same palette. MUST.
- **Non-finite scale factor**: `ThemeTypography.clampedSizeScale` maps NaN and infinities to 1.0, so `scaled(by:)` returns the receiver unchanged. MUST.
- **Compounded scale beyond the range**: each call clamps only its own factor, so two calls of 4 give a reader scale of 16. The source applies no cap to the product. MUST (to match the source).
- **Concurrent access**: not a concern; every property is an immutable `let` on a `Sendable` struct, and a scaled palette is a new value rather than a mutation.
- **Offline or disconnected state**: not applicable; the type does no I/O.
- **Cancellation and timeouts**: not applicable; every operation is synchronous, and the only loop (`dimmed`) takes at most 20 iterations.
- **Duplicate identity hues**: two ANSI slots with equal colors yield one entry in `identitySeriesColors`. MUST.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme` | `ColorTheme` | required | The only input to `init(theme:)`; supplies background, foreground, selection, cursor, ANSI table, `roleOverrides`, `typography` and `project` |
| `ColorTheme.roleOverrides` | dictionary from role raw value to `RGBAColor` | empty | Per-role overrides; keys that match no `ThemeRole` are never read |
| `factor` | `Double` | 1 (no scale) | Argument of `scaled(by:)`, clamped to 0.5 through 4 |
| `ThemeTypography.sizeScaleRange` | `ClosedRange<Double>` | 0.5 through 4 | Bound shared with `ThemeStore` |

No environment variables or settings keys are read; the host owns persistence of the theme and of the reader's text-size choice.

## Deep Linking

Not applicable: the file defines color roles and resolution only and has no screens or URL routes.

## Localization

Not applicable: the file contains no user-facing strings. The status-line examples in doc comments ("thought for 8s", "waiting to zeeble") belong to the chat view, not to this code.

## Accessibility Options

Not applicable: the file does not read Reduce Motion, Increase Contrast or Differentiate Without Color. Contrast is handled only by the derivation floors listed under `derive-text` and the 1.5 chart filter.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the file holds colors derived from a theme and collects, stores and transmits nothing.

## Logging

Not applicable: the source makes no log calls; every failure mode is a documented fallback.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/SemanticPalette.swift`; it imports only `Foundation`, so it compiles for macOS and iOS. A SwiftUI view builds `Color(.sRGB, red:green:blue:opacity:)` from an `RGBAColor`; the bridge lives in the UI layers. Pass the palette through the environment so a theme change re-renders every reader of `color(_:)`, and apply `scaled(by:)` at the environment boundary so one text-size control reaches every view.
- **Compose**: Model `ThemeRole` as an enum class and the palette as an immutable data class holding a map from role to `Color`; build the map once in the constructor, as the source does. Expose it with a `CompositionLocal` (`staticCompositionLocalOf`) so a theme change recomposes readers. Compose has no WCAG helper, so port `contrastRatio` and `dimmed` explicitly; `MaterialTheme.colorScheme` has fewer roles than 40, so keep this table as a layer over it rather than mapping onto it.
- **React/Web**: Emit each role as a CSS custom property on a root element (the source says the chat group mirrors web's `--pc-*` namespace) and resolve derivations in a pure TypeScript function that returns a frozen record. Use `color-mix(in srgb, ...)` only if its blending matches; the source blends encoded components linearly per channel, so compute the blend in script to be exact. A reader text scale maps to a `calc()` multiplier on a root font-size variable.
- **AppKit / UIKit**: The macOS layer adds `nsColor(_:)` and an `editorTheme` over this palette (see `SemanticPaletteEditorThemeTests`). Convert through `RGBAColor` so clamping happens before `NSColor` or `UIColor` creation. Observe theme changes and rebuild the palette once per change, since construction is the expensive step.
- **WinUI 3**: Use an `enum ThemeRole` and a `sealed record SemanticPalette(ColorTheme Theme)` that fills a `FrozenDictionary<ThemeRole, RgbaColor>` (`System.Collections.Frozen`) in its constructor; `Enum.GetValues<ThemeRole>()` replaces `CaseIterable`. Derivation uses a pure static method returning `RgbaColor`; port `dimmed` as a loop that steps the fraction down by 0.05. Expose the colors to XAML as `SolidColorBrush` entries in a `ResourceDictionary` that is swapped on theme change (`Application.Current.Resources.MergedDictionaries`), and bind with `ThemeResource` so controls update without code; implement `INotifyPropertyChanged` on a view-model wrapper only if the palette is rebound per property. Equality comes free from `record`, but `FrozenDictionary` does not compare by value, so compare the `Theme` and reader scale and rely on the map being derived from them. Windows high-contrast mode is separate: add `ResourceDictionary.ThemeDictionaries` entries named `HighContrast` so system colors win when the user turns it on, since this source has no such path. Hold the reader scale as a `double` property on a copy (`with` expression) and clamp with `Math.Clamp(factor, 0.5, 4)`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/SemanticPalette.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Every role is resolved once at construction and kept in a dictionary.
**Rationale**: The source comment says the dimmed-text roles run an iterative, pow-heavy contrast loop, and paying that on each draw or theme-apply call is wasteful. Because the map derives only from `theme`, equality is unaffected.
**Approved**: pending

**Decision**: Derived roles that depend on another role use that role's derived value, not its overridden value.
**Rationale**: The source calls `derive` on the parent role directly. The effect is that overriding `accent` or `elevatedSurface` does not move `onAccentText`, `personaName`, `userBubble`, `sendButton` or `card`. The source does not state why; it may be an accident of the recursion, so a port that wants overrides to flow through would be a deliberate change.
**Approved**: pending

**Decision**: `card` is its own role though it derives to `elevatedSurface`.
**Rationale**: The source comment says a theme can then set cards apart from pane title bars and footers without changing the tone they always had.
**Approved**: pending

**Decision**: `declares(_:)` reads the overrides rather than checking whether the color is visible.
**Rationale**: The source comment says every role derives to some opaque color, so the presence of an element such as a bubble outline must be the theme's explicit decision, as in web where a missing stylesheet variable means no border rule.
**Approved**: pending

**Decision**: `thinkingDoneText` and `thinkingIdleText` are derived from a desaturated foreground and are separate roles from `timestampText`.
**Rationale**: The source comments say the grey carries the meaning of a settled turn, a fixed `#8a8a8a` fails on light themes, a monochrome terminal palette has no grey to borrow, and a phosphor-green idle line would look like a turn that never ends. The done line is dimmer than the idle line on purpose, matching web's extra `opacity: 0.75`.
**Approved**: pending

**Decision**: `identitySeriesColors` removes state colors outright instead of ranking them last.
**Rationale**: The source comment says a view that also colors by state spends accent, success, warning and danger on meaning, so reusing one for identity would misreport health.
**Approved**: pending

**Decision**: The reader's text scale is held beside the theme and multiplied at read time, and `scaled(by:)` clamps its factor.
**Rationale**: The source comment separates the designer's `sizeScale` (a property of the typeface) from the reader's preference, which must survive a theme change. Clamping stops a slider from producing zero-height layout. The product of repeated calls is not capped, which is a documented edge case.
**Approved**: pending

**Decision**: A theme's project colors are optional, and the active-pane outline has no override.
**Rationale**: The source comment says a theme that recolors `paneOutline` restyles the frame while the front pane must still stand out, so the active outline is always `accent`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns is partial: the file keeps color math in `RGBAColor+Theme.swift` and the palette is a pure value, but it also carries chart hue lists, the reader text scale and three project-window colors beside the role table. Unit-test coverage is partial: `SemanticPaletteTests`, `SemanticPaletteRolesTests`, `SemanticPaletteScaleTests`, `ChatRoleDerivationTests` and `IdleStatusInkTests` cover overrides, ANSI mapping, text contrast floors, chart and identity lists, scaling and the thinking inks, but no test asserts the exact blend fractions, the `card` and `selectionEdge` derivations, the `chartSeriesColors` fallback to the five semantic colors, `projectPaneBackdrop` or `projectPaneOutline` in this suite, or compounding of repeated `scaled(by:)` calls. Explicit error handling passes because nothing can fail; each gap has a documented fallback. Caching strategy passes because roles are resolved once per instance, with the reason stated in the source. No-hardcoded-strings passes because the file has no user-facing string.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
