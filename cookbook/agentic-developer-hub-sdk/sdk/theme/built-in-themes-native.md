---
id: fd1f8d3c-6110-4687-a715-c8fa7c7caa5b
title: "Built-In Themes Native Adjustments"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Applies native-only chrome adjustments over the generated web-ported themes, so a generator re-run cannot drop them; today only Fishlamp is adjusted."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - color
  - logic
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Built-In Themes Native Adjustments

## Overview

`BuiltInThemes+Native.swift` extends the `BuiltInThemes` enum with the native app's adjustments to the themes ported from the web catalogue. `BuiltInThemes+Web.swift` is generated from the web CSS and must not be hand-edited, and the web catalogue has no tokens for the native chrome these adjustments touch (the selection fill, cards, the project window's plane). The adjustments therefore live in a separate file and are applied over the generated values, so a re-run of the generator cannot silently drop them.

The file exposes `webPortedNative`, the generated `webPorted` list with each theme passed through `nativeAdjusted`. `BuiltInThemes.all` is the hand-authored set followed by `webPortedNative`. Today exactly one theme is adjusted: Fishlamp. Its generated chrome put the selection (amber at 30% over near-black), the cards and settings groups, and the pane title bars on one warm grey-brown. The adjustment turns the selection into a cool slate marked with an amber line, and drops cards and the plane the panes sit on to the theme's own `#17130f`, so the title bars are the only thing left on that grey.

## Behavioral Requirements

- **native-list**: `BuiltInThemes.webPortedNative` MUST contain one entry for every theme in `BuiltInThemes.webPorted`, in the same order.
- **native-map**: `webPortedNative` MUST be the result of passing each `webPorted` theme through `nativeAdjusted`, and MUST NOT add, remove or reorder themes.
- **dispatch-by-id**: `nativeAdjusted` MUST select the adjustment by `theme.id`, never by name or position.
- **dispatch-fishlamp**: `nativeAdjusted` MUST apply the Fishlamp adjustment when `theme.id` equals the id of the generated `BuiltInThemes.fishlamp` theme.
- **dispatch-default**: `nativeAdjusted` MUST return any theme whose id has no adjustment unchanged.
- **input-preserved**: `nativeAdjusted` MUST NOT mutate its argument; the Fishlamp adjustment MUST work on a copy and return it.
- **fishlamp-selection**: The Fishlamp adjustment MUST set `selection` to `#232831ff`, replacing the generated amber `#e8a33d4d`.
- **fishlamp-card**: The Fishlamp adjustment MUST set `roleOverrides[ThemeRole.card.rawValue]` to `#17130fff`.
- **fishlamp-selection-edge**: The Fishlamp adjustment MUST set `roleOverrides[ThemeRole.selectionEdge.rawValue]` to `#e8a33dff`, so a selection is marked by an amber line.
- **fishlamp-pane-backdrop**: The Fishlamp adjustment MUST set `project` to a `ThemeProjectOptions` whose only non-nil field is `paneBackdrop`, equal to `#17130fff`.
- **fishlamp-project-replaced**: The Fishlamp adjustment MUST replace the theme's whole `project` value, discarding any `highlightActivePane` or `paneOutline` already present.
- **fishlamp-overrides-merged**: The Fishlamp adjustment MUST add or replace only the `card` and `selectionEdge` keys of `roleOverrides` and MUST leave every other key (for example the chat roles the generator emitted) as generated.
- **fishlamp-untouched-fields**: The Fishlamp adjustment MUST NOT change `id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `ansi` or `typography`.
- **ember-shared**: The Fishlamp adjustment MUST use one value, named `ember` (`#17130fff`, the theme's own ANSI slot 8), for both the card colour and the pane backdrop.
- **hex-literals**: The adjustment parses its colours with `RGBAColor(hexString:)` and force-unwraps the result; the three literals are valid 8-digit `RRGGBBAA` strings, so the parse does not fail at runtime.
- **access**: `webPortedNative` and `nativeAdjusted` are internal to the SDK module (no `public`), and `fishlampNative` is `private`; consumers read the result only through `BuiltInThemes.all` and `BuiltInThemes.theme(withID:)`.
- **concurrency**: Both members are pure and synchronous. `webPortedNative` is a `static let`, initialised once, lazily and thread-safely, by the language runtime on first access; the file declares no actor, lock or queue.
- **side-effects**: The file performs no file, network, process or notification side effects and writes no logs.

## Appearance

Not applicable — this is a set of colour-value adjustments applied to theme data, not a visual component. The values it sets are listed under Behavioral Requirements.

## States

Not applicable — this is stateless theme-data code, not a visual component; it has no visual states.

## Accessibility

Not applicable — this is theme-data code, not a visual component.

## Conformance Test Vectors

The source ships no test that asserts the adjustments directly. Vector native-002 follows the `BuiltInThemesTests` assertion of 36 themes in `all`, and native-001 is consistent with the `PortedThemeTests` assertions (the `webPorted` name set, unique ids across `all`); the rest are derived from the source itself.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| native-001 | native-list, native-map | `BuiltInThemes.webPortedNative.map(\.id)` against `BuiltInThemes.webPorted.map(\.id)` | The two id arrays are equal, element by element (consistent with the `PortedThemeTests` ported-name set and unique-id assertions; no test compares the two lists directly) |
| native-002 | native-map | `BuiltInThemes.all.count` | 36, the hand-authored set plus `webPortedNative` (`BuiltInThemesTests`) |
| native-003 | dispatch-default | `nativeAdjusted` on the first `webPorted` theme whose id is not `BuiltInThemes.fishlamp.id` | The returned theme is equal to the input |
| native-004 | dispatch-fishlamp, fishlamp-selection | `nativeAdjusted(BuiltInThemes.fishlamp).selection.hexString` | `#232831FF` |
| native-005 | fishlamp-card, ember-shared | `nativeAdjusted(BuiltInThemes.fishlamp).roleOverrides[ThemeRole.card.rawValue]?.hexString` | `#17130FFF` |
| native-006 | fishlamp-selection-edge | `nativeAdjusted(BuiltInThemes.fishlamp).roleOverrides[ThemeRole.selectionEdge.rawValue]?.hexString` | `#E8A33DFF` |
| native-007 | fishlamp-pane-backdrop, fishlamp-project-replaced, ember-shared | `nativeAdjusted(BuiltInThemes.fishlamp).project` | `ThemeProjectOptions(paneBackdrop: #17130FFF)` with `highlightActivePane` and `paneOutline` nil |
| native-008 | fishlamp-overrides-merged | `nativeAdjusted(BuiltInThemes.fishlamp).roleOverrides[ThemeRole.chatSurface.rawValue]?.hexString` | `#17130FF0`, as generated |
| native-009 | fishlamp-untouched-fields | Compare `id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `ansi` and `typography` of `nativeAdjusted(BuiltInThemes.fishlamp)` with `BuiltInThemes.fishlamp` | All equal |
| native-010 | input-preserved | Read `BuiltInThemes.fishlamp.selection.hexString` after calling `nativeAdjusted(BuiltInThemes.fishlamp)` | `#E8A33D4D`, the generated value |
| native-011 | dispatch-by-id | A copy of `BuiltInThemes.fishlamp` with `name` changed to "Other" | The Fishlamp adjustment is still applied (`selection` is `#232831FF`) |
| native-012 | dispatch-by-id, dispatch-default | A copy of `BuiltInThemes.fishlamp` with `id` changed to a new string | Returned unchanged; `selection` stays `#E8A33D4D` |
| native-013 | fishlamp-project-replaced | A copy of `BuiltInThemes.fishlamp` with `project` set to `ThemeProjectOptions(highlightActivePane: true)` | The adjusted `project` has `highlightActivePane` nil and `paneBackdrop` `#17130FFF` |
| native-014 | hex-literals | `RGBAColor(hexString: "#17130fff")`, `"#232831ff"`, `"#e8a33dff"` | Each returns non-nil |

## Edge Cases

- **Theme id with no adjustment**: MUST be returned unchanged. This covers every `webPorted` theme except Fishlamp, and a theme with an id the switch has never seen.
- **Empty `webPorted`**: `webPortedNative` is then empty and `all` is the hand-authored set alone; the map has no precondition on the list's length.
- **Fishlamp already carrying a `card`, `selectionEdge` or `project` value**: the adjustment MUST overwrite the `card` and `selectionEdge` keys and replace `project`; it does not merge with a prior `ThemeProjectOptions`.
- **Fishlamp `roleOverrides` missing the other keys**: the adjustment MUST still succeed, because it assigns through a dictionary subscript, which creates the entries.
- **Generator re-run**: regenerating `BuiltInThemes+Web.swift` MUST NOT remove the adjustments, because they live in this file and are applied after the generated list is read.
- **Generated Fishlamp renamed or removed**: the case compares against `fishlamp.id` read from the generated constant rather than a literal, so a changed id is followed automatically; a renamed or removed `fishlamp` constant stops the file compiling, which is the signal.
- **Malformed hex literal**: not reachable at runtime with the current literals, since `RGBAColor(hexString:)` is force-unwrapped. A mistyped literal in a future edit would trap at first access of `webPortedNative`, and thus of `BuiltInThemes.all`.
- **Concurrent access**: `webPortedNative` is a `static let` and initialises exactly once under the language runtime's guarantee; `nativeAdjusted` is pure and may be called from any thread.
- **Error states, offline and cancellation**: not applicable — the code does no I/O, awaits nothing and cannot throw.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `BuiltInThemes.webPorted` | `[ColorTheme]` | the generated list | The input list, read from `BuiltInThemes+Web.swift`; the only dependency this file takes |
| `theme.id` | `String` | per theme | The key `nativeAdjusted` switches on |
| `ember` | `RGBAColor` | `#17130fff` | Fishlamp's card colour and pane backdrop |
| Fishlamp selection | `RGBAColor` | `#232831ff` | Cool slate selection fill |
| Fishlamp selection edge | `RGBAColor` | `#e8a33dff` | Amber line marking a selection |

The file reads no environment variables or settings keys and injects no dependencies.

## Deep Linking

Not applicable: the file only adjusts theme colour values and exposes no route, URL or screen.

## Localization

Not applicable: the file contains no user-facing strings; every literal is a colour value.

## Accessibility Options

Not applicable: the file is theme data and does not read Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the adjustments apply unconditionally and the file reads no flag.

## Analytics

Not applicable: the file emits no events.

## Privacy

Not applicable: the file handles only built-in colour constants and collects, stores and transmits no user data.

## Logging

Not applicable: the file contains no log call; it has no failure path to report.

## Platform Notes

- **SwiftUI**: Source platform for the model. The file is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/BuiltInThemes+Native.swift`, an `extension BuiltInThemes` importing only `Foundation`, so it is shared by macOS and iOS. Colours reach SwiftUI through `SemanticPalette+SwiftUI.swift`, where `selectionEdge` is a `Color`.
- **Compose**: Express the same thing as a function over an immutable theme data class: `webPortedNative = webPorted.map(::nativeAdjusted)`, with a `when (theme.id)` and `theme.copy(...)` for Fishlamp. Kotlin `Map.plus` copies the role-override map instead of mutating it. Colours become `Color(0xFF232831)` and so on; Compose packs alpha first (`AARRGGBB`), where this source writes `RRGGBBAA`.
- **React/Web**: The web catalogue's CSS is the origin of the generated themes, so a web port needs no adjustment layer; the native-only tokens (`card`, `selectionEdge`, `paneBackdrop`) would be added as CSS custom properties on the Fishlamp theme. In TypeScript, use a pure function returning a spread copy so the generated object is never mutated.
- **AppKit / UIKit**: Consumers read the adjusted values through the palette, for example `SemanticPalette+NSColor.swift` (`selectionEdgeColor`), `TabPaneView` (outlines a selected card when `selectionEdge` has alpha above zero) and `ThemedViews` (draws a 2-point leading bar in `selectionEdge`, flipped under right-to-left layout). UIKit would read the same palette through `UIColor`.
- **WinUI 3**: Model the theme as a C# `record` so `with` expressions give the copy-and-adjust behaviour: `WebPortedNative = WebPorted.Select(NativeAdjusted).ToList()` and a `switch` expression on `theme.Id` returning `theme with { Selection = slate, RoleOverrides = theme.RoleOverrides.SetItem("card", ember).SetItem("selectionEdge", amber), Project = new ThemeProjectOptions(PaneBackdrop: ember) }`, with `RoleOverrides` an `ImmutableDictionary` from `System.Collections.Immutable`. Parse colours with `Windows.UI.Color.FromArgb` (alpha first), since the source's `RRGGBBAA` order differs. Publish the values as `SolidColorBrush` entries in a `ResourceDictionary` swapped through `Application.Resources.MergedDictionaries`, using `ThemeDictionaries` with `Dark` and `Light` keys for the appearance. Selection fill and edge map to the `ListViewItem` `Selected` and `SelectedPointerOver` visual states through the `ListViewItemBackgroundSelected` and `ListViewItemSelectionIndicatorBrush` theme resources. A `static readonly` field in a static class gives the same once-only initialisation as `static let`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/BuiltInThemes+Native.swift` | confirmed (1.0.1) |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |

## Design Decisions

**Decision**: Keep the native adjustments in `BuiltInThemes+Native.swift` and apply them over the generated list rather than editing `BuiltInThemes+Web.swift`.
**Rationale**: The generated file is rebuilt from the web CSS and must not be hand-edited, and the web catalogue has no tokens for the native chrome (selection fill, cards, the project window's plane); a separate layer survives a generator re-run, as the file's own comment states.
**Approved**: pending

**Decision**: Dispatch on `theme.id` through a `switch` with a `default` that returns the theme unchanged.
**Rationale**: Ids are stable (persisted selections rely on them) while names and positions are not, and the default keeps every unadjusted theme exactly as generated.
**Approved**: pending

**Decision**: Move the selection to a cool slate with an amber `selectionEdge` line, and set `card` and `paneBackdrop` to `#17130f`.
**Rationale**: The generated chrome put the selection, the cards and the pane title bars on one warm grey-brown; separating them leaves the title bars as the only element on that grey, per the file's doc comment.
**Approved**: pending

**Decision**: Replace `project` wholesale with a `ThemeProjectOptions` carrying only `paneBackdrop`.
**Rationale**: `nil` for `highlightActivePane` and `paneOutline` leaves them to the Projects settings panel and the theme's outline tone, as `ThemeProjectOptions` documents; the side effect is that any value already in those two fields would be discarded. The generated Fishlamp theme sets no `project`, so nothing is lost today.
**Approved**: pending

**Decision**: No unit test asserts the adjusted Fishlamp values; the vectors above are derived from source and from the whole-list tests.
**Rationale**: The existing tests cover `all` as a whole (size, unique ids, ported membership) but none reads `selection`, `card`, `selectionEdge` or `project` of Fishlamp, so a change to those literals would pass the suite.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |

Separation of concerns passes: the adjustments are isolated from the generated file and from the hand-authored set, and the file's one job is applying them. Unit test coverage is partial: the suite checks `BuiltInThemes.all` and the ported set as a whole, but nothing asserts the Fishlamp values this file sets. Explicit error handling is partial: the colour literals are force-unwrapped, which is safe for the current valid constants but would trap rather than report if one were mistyped. Data integrity passes: the function copies its input and never mutates the generated theme.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
