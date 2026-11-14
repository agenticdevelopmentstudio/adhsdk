---
id: 4b0159a7-3ee0-44d7-bd43-8b7ae5d64e8d
title: "Built-In Themes (Web Catalogue)"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "The 21 generated brand themes ported from the web CSS catalogue: stable ids, derived ANSI fill, exact chat role overrides, web font stacks and type scales."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - color
  - typography
  - built-in
  - chat
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Built-In Themes (Web Catalogue)

## Overview

`BuiltInThemes.webPorted` is an ordered list of 21 `ColorTheme` values that the Swift SDK generates from the web theme stylesheets (`packages/web/packages/themes/src/styles/*.css`), so the Swift and web catalogues match. They are brand themes with no ANSI palette of their own. Each carries a 16-colour `ansi` array filled in from its semantic colours, a `roleOverrides` map holding the exact web chat values, and a `typography` value holding the web font stack and type scale. The list is generated (`scripts/generate_web_theme_swift.py`, fed by `scripts/extract_web_themes.py`) and must be changed by re-running the generator, never by hand. This recipe specifies the contract of the generated data: which themes exist, what shape each one has, and how the web values were projected onto it.

The catalogue is 21 of the web manifest's 39 keys. The eight `adh*` font-variant themes are absent because they share one palette and differ only in typography, a web font-loading concern. The ten editor palettes (dracula, nord, gruvbox, solarized, catppuccin, github, monokai, one-dark, tokyo-night, rose-pine) are absent because Swift already ships them as terminal themes with real ANSI palettes.

## Behavioral Requirements

- **catalogue-membership**: `webPorted` MUST contain exactly these 21 themes by `name`, in this order: Charcoal, Signal, Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal, CRT Monitor, Handheld Communicator, Synthwave '84, Cobalt2, Vesper, Professional, Techy, Whimsical, Fishlamp, Dev Team, Mike Fullerton, My Projects, Projects Overview, Agentic Development Studio.
- **catalogue-names-verbatim**: Each `name` MUST be the web manifest's own label, including the parentheses in "Green Matrix (Glass)" and the apostrophe in "Synthwave '84".
- **catalogue-no-editor-duplicates**: `webPorted` MUST NOT contain a theme whose `name` equals the name of any hand-authored theme in `BuiltInThemes.all`.
- **catalogue-visibility**: Every theme in `webPorted` MUST appear in `BuiltInThemes.all`. The list the app ships is `webPortedNative`, which is `webPorted` mapped through `nativeAdjusted` in `BuiltInThemes+Native.swift`.
- **theme-id-stable**: Each theme's `id` MUST be the fixed string `B1B6F0E2-0000-4000-8000-000000000NNN`, where `NNN` runs from `101` (Charcoal) to `121` (Agentic Development Studio) in list order. Ids are never derived at runtime.
- **theme-id-unique**: The ids of `BuiltInThemes.all` MUST be pairwise distinct.
- **theme-appearance**: Every theme MUST declare `appearance: .dark`.
- **theme-built-in**: Every theme MUST set `isBuiltIn` to `true`.
- **theme-attribution**: Every theme MUST set `attribution` to "Agentic Developer Hub SDK".
- **theme-base-colours**: Each theme MUST give `foreground`, `background`, `cursor` and `selection` as `RGBAColor` values built from 8-digit `#RRGGBBAA` strings. The values per theme are in the catalogue table below.
- **theme-selection-from-cursor**: Each theme's `selection` MUST be its `cursor` colour at alpha `4d` (about 30%).
- **ansi-count**: Each theme's `ansi` MUST hold exactly 16 colours, so `hasValidPalette` is true (`ColorTheme.ansiColorCount` is 16).
- **ansi-derived-fill**: `ansi` is a best-effort fill derived from the theme's semantic colours for the terminal feature, not a palette the web theme defines. In every theme index 0 MUST equal `background` and index 15 MUST equal `foreground`.
- **ansi-bright-repeats-normal**: In every theme, indices 1 to 6 MUST equal indices 9 to 14 respectively (the bright half repeats the normal half for those six slots).
- **ansi-accent-slots**: In every theme except CRT Monitor and Handheld Communicator, indices 4 and 5 MUST equal the theme's `cursor` (its accent). In CRT Monitor and Handheld Communicator, indices 3 and 4 MUST equal the accent `#00ff41ff`.
- **ansi-no-warning-no-link**: CRT Monitor and Handheld Communicator have no `--color-warning` or `--color-link` in their CSS. Their `ansi[3]` and `ansi[11]` MUST fall back to the accent, and their `ansi[5]` and `ansi[13]` MUST be `#005fffff`, the accent shifted toward magenta in place of `--color-link` as the source comment describes.
- **ansi-transparent-background**: CRT Monitor and Handheld Communicator MUST carry a fully transparent `background` (`#00000000`), and therefore a fully transparent `ansi[0]`; their `ansi[8]` MUST be `#050805ff`.
- **role-overrides-keyed**: `roleOverrides` MUST be keyed by `ThemeRole.rawValue` and hold `RGBAColor` values. Any role a theme does not list is left to `SemanticPalette` to derive.
- **role-overrides-universal**: Every theme MUST override the nine chat roles every web theme defines: `chatSurface`, `chatInputBackground`, `chatInputBorder`, `chatInputFocus`, `personaName`, `personaText`, `userName`, `userText` and `timestampText`.
- **role-overrides-bubble-fills**: Every theme MUST override `personaBubble` and `userBubble`, either with the web fill or, where web declares none, with `#00000000`.
- **role-overrides-optional**: The roles `personaBubbleBorder`, `userBubbleBorder`, `sendButton`, `sendButtonHover`, `sendButtonText` and `thinkingDoneText` MUST be present only in the themes whose CSS declares them and MUST be absent elsewhere, where they derive. The per-theme sets are in the requirements below and the role table in the catalogue section.
- **flat-terminal-themes**: Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal, CRT Monitor and Handheld Communicator MUST override both `personaBubble` and `userBubble` to `#00000000`. Their CSS declares no `--pc-persona-bg` or `--pc-user-bg`, and `.pc-bubble` styles only its width, so web draws no box. The transparent override is explicit rather than left to derive; the chat bubble view reads it as a flat transcript line with no padding and no corner radius.
- **flat-terminal-no-send-button**: The seven flat themes MUST NOT override `sendButton`, `sendButtonHover` or `sendButtonText`.
- **thinking-done-declared**: CRT Monitor and Handheld Communicator MUST override `thinkingDoneText` to `#00ff41ff`.
- **thinking-done-not-elsewhere**: No other theme MUST override `thinkingDoneText`; in particular Old School Terminal MUST NOT, so its settled status line takes the library default grey even though it shares a phosphor palette with the two CRT themes.
- **whimsical-gradient-first-stop**: Whimsical's web CSS defines `--pc-persona-bg`, `--pc-user-bg` and `--pc-send-bg` as `linear-gradient(...)`. `ColorTheme` holds solid colours only, so Whimsical MUST use each gradient's first colour stop: `personaBubble` `#c8506aff`, `userBubble` `#5a4a98ff`, `sendButton` `#c8506aff`.
- **transparent-send-button**: Dev Team, Mike Fullerton and Projects Overview MUST override `sendButton` to `#00000000` and `sendButtonText` to the accent `#c4a35aff`, a text-only send button.
- **send-button-hover-absent**: Techy, Whimsical, Dev Team, Mike Fullerton and Projects Overview MUST NOT override `sendButtonHover`.
- **send-button-hover-present**: Charcoal, Signal, Synthwave '84, Cobalt2, Vesper, Professional, Fishlamp, My Projects and Agentic Development Studio MUST override `sendButtonHover`, alongside `sendButton` and `sendButtonText`.
- **bubble-borders-declared**: `personaBubbleBorder` and `userBubbleBorder` MUST be overridden in Charcoal, Techy, Fishlamp, Dev Team, Mike Fullerton, My Projects, Projects Overview and Agentic Development Studio, and MUST NOT be overridden in the other thirteen themes.
- **typography-roles**: Every theme's `typography.styles` MUST hold a `FontStyle` for each of the six `TextRole` cases, keyed by `TextRole.rawValue`, with these base sizes and weights: title 22 semibold, heading 15 semibold, body 13 regular, caption 11 regular, code 12 regular, button 13 medium.
- **typography-family**: Title, heading, body, caption and button MUST share the theme's first named web font family; `code` MUST use the family of the theme's `--font-mono` stack. Where the two coincide (Charcoal, Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal, CRT Monitor, Handheld Communicator, Fishlamp, Mike Fullerton) all six roles use one family. The families per theme are in the catalogue table.
- **typography-monospaced-flag**: Each `FontStyle.monospaced` MUST come from the font stack's own generic fallback: true for every role of a monospaced stack, false for the non-code roles of a proportional stack, and true for `code` in every theme. Sans themes are not forced monospaced.
- **typography-size-scale**: `ThemeTypography.sizeScale` MUST carry each theme's web body size as a ratio against a catalogue baseline of 15px, not as transcribed point sizes: Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Techy, Dev Team and My Projects 0.9333 (14px); Old School Terminal and Whimsical 1.0667 (16px); CRT Monitor and Handheld Communicator 1.2667 (19px); Mike Fullerton 0.9 (13.5px); Projects Overview 0.8667 (13px).
- **typography-size-scale-default**: A theme whose CSS states no body size MUST leave `sizeScale` at its default of 1.0: Charcoal, Signal, Synthwave '84, Cobalt2, Vesper, Professional, Fishlamp and Agentic Development Studio.
- **typography-scale-reaches-size**: The scale MUST affect the resolved size: `typography.size(.body)` is the body style's `size` times `sizeScale`, so Old School Terminal resolves larger than its base 13.
- **generated-source**: `BuiltInThemes+Web.swift` MUST be produced by the generator and MUST NOT be hand-edited. Native-only changes to a generated theme (selection fill, cards, the project plane) MUST live in `BuiltInThemes+Native.swift`, applied over the generated values, so a re-run cannot drop them. Today that file adjusts only Fishlamp.
- **hex-literals-valid**: The generator MUST emit only valid 8-digit hex literals, because every colour is built with `RGBAColor(hexString:)` and force-unwrapped; a malformed literal traps when the static theme is first read and is not a recoverable condition.
- **no-side-effects**: Reading `webPorted` MUST NOT touch files, the network, processes or notifications. Every theme is a `static let` on `BuiltInThemes`, an `enum` with no stored state, and `ColorTheme` is a value type.

### Catalogue

Base colours, type scale and font families per theme. Every theme also has the six-role type sizes above, `appearance: .dark`, and `selection` equal to `cursor` at alpha `4d`.

| Swift name | Theme name | id suffix | foreground | background | cursor | sizeScale | body family | code family |
|---|---|---|---|---|---|---|---|---|
| `charcoal` | Charcoal | 101 | `#e8e6e3ff` | `#0c0c0fff` | `#c4a35aff` | 1.0 (unset) | Iosevka | Iosevka |
| `signal` | Signal | 102 | `#ece8dfff` | `#0a0c11ff` | `#f6b73cff` | 1.0 (unset) | Space Grotesk | JetBrains Mono |
| `terminal` | Terminal | 103 | `#b0b0b0ff` | `#0a0a0aff` | `#33ff33ff` | 0.9333 | IBM Plex Mono | IBM Plex Mono |
| `terminalSplit` | Terminal Split | 104 | `#d0d0d0ff` | `#0a0a0aff` | `#ffcc00ff` | 0.9333 | IBM Plex Mono | IBM Plex Mono |
| `greenMatrix` | Green Matrix | 105 | `#00ff41ff` | `#000000ff` | `#00ff41ff` | 0.9333 | JetBrains Mono | JetBrains Mono |
| `greenMatrixGlass` | Green Matrix (Glass) | 106 | `#00ff41ff` | `#000000ff` | `#00ff41ff` | 0.9333 | JetBrains Mono | JetBrains Mono |
| `oldSchoolTerminal` | Old School Terminal | 107 | `#00ff41ff` | `#000000ff` | `#00ff41ff` | 1.0667 | VT323 | VT323 |
| `crtMonitor` | CRT Monitor | 108 | `#00ff41ff` | `#00000000` | `#00ff41ff` | 1.2667 | VT323 | VT323 |
| `handheldCommunicator` | Handheld Communicator | 109 | `#00ff41ff` | `#00000000` | `#00ff41ff` | 1.2667 | VT323 | VT323 |
| `synthwave84` | Synthwave '84 | 110 | `#f2f0f5ff` | `#262335ff` | `#ff7edbff` | 1.0 (unset) | Exo 2 | JetBrains Mono |
| `cobalt2` | Cobalt2 | 111 | `#ffffffff` | `#193549ff` | `#ffc600ff` | 1.0 (unset) | Rubik | Victor Mono |
| `vesper` | Vesper | 112 | `#ffffffff` | `#101010ff` | `#ffc799ff` | 1.0 (unset) | Geist | Geist Mono |
| `professional` | Professional | 113 | `#e8eaedff` | `#0e1620ff` | `#8aa8d4ff` | 1.0 (unset) | Inter | JetBrains Mono |
| `techy` | Techy | 114 | `#c9d1d9ff` | `#0d1117ff` | `#00ff88ff` | 0.9333 | Inter | JetBrains Mono |
| `whimsical` | Whimsical | 115 | `#f5e8f5ff` | `#1a1024ff` | `#f08aa8ff` | 1.0667 | Nunito | JetBrains Mono |
| `fishlamp` | Fishlamp | 116 | `#f0e4d0ff` | `#0b0a09ff` | `#e8a33dff` | 1.0 (unset) | Iosevka | Iosevka |
| `devTeam` | Dev Team | 117 | `#e8e6e3ff` | `#14141aff` | `#c4a35aff` | 0.9333 | Manrope | DM Mono |
| `mikeFullerton` | Mike Fullerton | 118 | `#e8e6e3ff` | `#0e0e14ff` | `#c4a35aff` | 0.9 | DM Mono | DM Mono |
| `myProjects` | My Projects | 119 | `#e8e6e3ff` | `#14141aff` | `#c4a35aff` | 0.9333 | Manrope | DM Mono |
| `projectsOverview` | Projects Overview | 120 | `#e8e6e3ff` | `#14141aff` | `#c4a35aff` | 0.8667 | Manrope | DM Mono |
| `agenticDevelopmentStudio` | Agentic Development Studio | 121 | `#e8e6e3ff` | `#0c0c0fff` | `#c4a35aff` | 1.0 (unset) | Manrope | DM Mono |

Chat role overrides per theme, beyond the nine universal roles and the two bubble fills:

| Theme | Extra overridden roles |
|---|---|
| Charcoal, Fishlamp, My Projects, Agentic Development Studio | `personaBubbleBorder`, `userBubbleBorder`, `sendButton`, `sendButtonHover`, `sendButtonText` |
| Signal, Synthwave '84, Cobalt2, Vesper, Professional | `sendButton`, `sendButtonHover`, `sendButtonText` |
| Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal | none |
| CRT Monitor, Handheld Communicator | `thinkingDoneText` |
| Techy | `personaBubbleBorder`, `userBubbleBorder`, `sendButton`, `sendButtonText` |
| Whimsical | `sendButton`, `sendButtonText` |
| Dev Team, Mike Fullerton, Projects Overview | `personaBubbleBorder`, `userBubbleBorder`, `sendButton` (transparent), `sendButtonText` |

Other values worth stating. Green Matrix (Glass), Old School Terminal, CRT Monitor and Handheld Communicator set `chatInputBackground` to `#00000000`. Green Matrix (Glass) and Old School Terminal set `chatSurface` to `#050805cc`; CRT Monitor and Handheld Communicator set it to `#040c069e`. Dev Team, My Projects and Projects Overview set `chatInputBackground` to `#0c0c0fff` while their `background` is `#14141aff`. Mike Fullerton's `chatInputBackground` is `#0c0c0f99`, its `chatSurface` is `#0e0e148c` and its `ansi[8]` is `#14141cb2`.

## Appearance

Not applicable — this is generated colour and typography data, not a visual component. The values it supplies are rendered by other components.

## States

Not applicable — this is a set of static constants, not a visual component, and it has no runtime state machine: each theme is created once from literals and never changes.

## Accessibility

Not applicable — this is theme data, not a visual component. Contrast between the supplied foreground, background and role colours is not checked in this source.

## Conformance Test Vectors

Derived from `PortedThemeTests` (Swift Testing suite "Ported web themes") and from the literals in `BuiltInThemes+Web.swift`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-web-001 | catalogue-membership, catalogue-names-verbatim | Set of `names` of `webPorted` (test `catalogMatchesWeb`) | Equals the 21 names listed, including "Green Matrix (Glass)" and "Synthwave '84" |
| theme-web-002 | catalogue-no-editor-duplicates, theme-id-unique | Names of `BuiltInThemes.all` minus `webPorted`, and ids of `all` (test `noDuplicateNames`) | No ported name is among the remainder; the number of distinct ids equals `all.count` |
| theme-web-003 | ansi-count, theme-built-in | For each ported theme, `theme.hasValidPalette` and `theme.isBuiltIn` (test `palettesAreValid`) | Both true for all 21 |
| theme-web-004 | role-overrides-universal | For each ported theme, `roleOverrides[role.rawValue]` for the nine universal chat roles (test `chatOverridesArePresent`) | Non-nil for every theme and role |
| theme-web-005 | flat-terminal-themes, role-overrides-bubble-fills | `SemanticPalette(theme:)` alpha of `personaBubble` and `userBubble` for each ported theme (test `themesWithoutWebBubbleFillsAreFlat`) | Alpha is 0 for both in exactly the seven flat themes and no others |
| theme-web-006 | typography-roles | Each ported theme, each `TextRole.allCases` (test `typographyIsPorted`) | `typography.styles[role.rawValue]` is non-nil |
| theme-web-007 | typography-family, typography-monospaced-flag | Old School Terminal `style(.body)`; Professional `style(.body)` and `style(.code)` (test `typographyIsPorted`) | Old School Terminal family "VT323", monospaced; Professional body "Inter" not monospaced, code "JetBrains Mono" monospaced |
| theme-web-008 | typography-size-scale, typography-size-scale-default | `sizeScale` of Old School Terminal, CRT Monitor, Handheld Communicator, Terminal, Charcoal (test `bodyFontSizeIsPortedAsAScale`) | 16/15, 19/15, 19/15, 14/15 each within 0.001; Charcoal exactly 1.0 |
| theme-web-009 | typography-scale-reaches-size | Old School Terminal `typography.size(.body)` versus `style(.body).size` (test `bodyFontSizeIsPortedAsAScale`) | The resolved size is greater than the base size |
| theme-web-010 | thinking-done-declared | `palette.declares(.thinkingDoneText)` and its colour for CRT Monitor and Handheld Communicator (test `thinkingDoneColourIsDeclaredByTerminalThemes`) | Declared, colour `#00ff41ff`, and different from `timestampText` |
| theme-web-011 | thinking-done-not-elsewhere | Old School Terminal `palette.declares(.thinkingDoneText)` and its derived colour (test `oldSchoolTerminalSettlesToGrey`) | Not declared; red, green and blue channels differ by less than 0.02 (grey) |
| theme-web-012 | thinking-done-not-elsewhere | Whimsical `palette.declares(.thinkingDoneText)` and its alpha (test `thinkingDoneColourIsDerivedElsewhere`) | Not declared; derived alpha greater than 0 |
| theme-web-013 | catalogue-visibility | For each ported theme, whether `BuiltInThemes.all` holds one with the same id (test `foldedIntoAll`) | True for all 21 |
| theme-web-014 | theme-id-stable | Charcoal `id` and Agentic Development Studio `id` | `B1B6F0E2-0000-4000-8000-000000000101` and `B1B6F0E2-0000-4000-8000-000000000121` |
| theme-web-015 | ansi-derived-fill, ansi-bright-repeats-normal | Any theme, compare `ansi[0]`, `ansi[15]`, `ansi[1]` to `background`, `foreground`, `ansi[9]` | `ansi[0]` equals `background`, `ansi[15]` equals `foreground`, `ansi[1]` equals `ansi[9]` |
| theme-web-016 | whimsical-gradient-first-stop | Whimsical `roleOverrides` for `personaBubble`, `userBubble`, `sendButton` | `#c8506aff`, `#5a4a98ff`, `#c8506aff` |
| theme-web-017 | theme-selection-from-cursor, theme-base-colours | Synthwave '84 `cursor` and `selection` | `#ff7edbff` and `#ff7edb4d` |
| theme-web-018 | transparent-send-button, send-button-hover-absent | Mike Fullerton `sendButton` and `sendButtonText`; presence of `sendButtonHover` | `#00000000`, `#c4a35aff`; no `sendButtonHover` override |
| theme-web-019 | ansi-accent-slots, ansi-no-warning-no-link, ansi-transparent-background | CRT Monitor `ansi[0]`, `ansi[3]`, `ansi[5]`, `ansi[13]` | `#00000000`, `#00ff41ff`, `#005fffff`, `#005fffff` |
| theme-web-020 | flat-terminal-no-send-button, role-overrides-optional | Presence of `sendButton`, `sendButtonHover`, `sendButtonText` in Terminal `roleOverrides` | All three absent |
| theme-web-021 | bubble-borders-declared | Presence of `personaBubbleBorder` in Charcoal and in Signal `roleOverrides` | Present (`#c4a35a40`) in Charcoal; absent in Signal |
| theme-web-022 | typography-roles, typography-monospaced-flag | Techy `style(.title)` and `style(.code)` | Title Inter 22 semibold not monospaced; code JetBrains Mono 12 regular monospaced |
| theme-web-023 | send-button-hover-present | Presence of `sendButtonHover` in Signal `roleOverrides` | Present, `#ffc85aff` |
| theme-web-024 | theme-appearance, theme-attribution | Any ported theme's `appearance` and `attribution` | `.dark` and "Agentic Developer Hub SDK" |
| theme-web-025 | hex-literals-valid | `RGBAColor(hexString: "#12345")` (five digits) | `nil`, which a force-unwrap in the generated file would turn into a trap |

## Edge Cases

- **Theme with no CSS-declared body size** (MUST): `sizeScale` stays 1.0 rather than a guessed ratio; eight themes are in this state (test `bodyFontSizeIsPortedAsAScale`, Charcoal).
- **Web gradient where `ColorTheme` holds a solid** (MUST): the first colour stop is used, sampled deterministically, and the rest of the gradient is dropped. This is lossy by design and recorded in the doc comment on Whimsical.
- **Theme that declares no bubble fill** (MUST): the fill is an explicit `#00000000` override, not a missing key, so derivation cannot invent a visible bubble.
- **Theme with no `--color-warning` or `--color-link`** (MUST): CRT Monitor and Handheld Communicator fill `ansi` slots 3 and 11 from the accent and slots 5 and 13 with `#005fffff`.
- **Fully transparent `background`** (MUST): CRT Monitor and Handheld Communicator carry `#00000000`, so `ansi[0]` is also transparent; a consumer that needs an opaque cell colour must composite it, because this source does not.
- **Optional chat roles absent** (MUST): a missing `sendButton` role, bubble border or `thinkingDoneText` key means "derive", not "transparent" or "none". Where web means transparent the source says so with `#00000000`.
- **Font family not installed** (SHOULD): the source names only the first family of each web stack and records no fallback chain; its doc comments state the face falls back to the system face at the same metrics when the family is not installed. Only `VT323` is bundled and registered (by `ToolkitFonts`); every other family relies on the host's installed fonts. That fallback is applied where `FontStyle` is resolved to a platform font, outside this file.
- **Malformed colour literal** (MUST): `RGBAColor(hexString:)` returns nil for anything but 8 hex digits after an optional leading `#`, and this file force-unwraps, so a bad literal traps on first read. The generator is responsible for emitting valid literals.
- **Native adjustment over a generated theme** (MUST): `webPortedNative` replaces Fishlamp's `selection` with `#232831ff`, sets `card` and `selectionEdge` overrides and a `project` backdrop, so the shipped Fishlamp differs from the generated one in `webPorted`.
- **Concurrent access**: not applicable — every theme is an immutable `static let` value built once from literals, with no mutation path in this source.
- **Offline or disconnected state**: not applicable — the file performs no network or file access.
- **Null and empty input**: not applicable — the catalogue takes no input; the only absent values are intentional, such as the optional roles above and the `project` options, which only Fishlamp's native adjustment sets.
- **Boundary values**: the `sizeScale` values here (0.8667 to 1.2667) sit inside `ThemeTypography.sizeScaleRange` (0.5 to 4), so the range clamp never applies to them.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `BuiltInThemes.webPorted` | `[ColorTheme]` | the 21 themes above | The generated catalogue; read-only |
| `ThemeTypography.sizeScale` | `Double` | 1.0 | Per theme; set from the web body size over a 15px baseline |
| Generator inputs | files | none | `scripts/extract_web_themes.py` output (from `packages/web/packages/themes/src/styles/*.css`), consumed by `scripts/generate_web_theme_swift.py` |

The theme data takes no environment variables, settings keys or injected dependencies at read time.

## Deep Linking

Not applicable: the file defines static theme constants and routes to no screen or URL.

## Localization

Not applicable: theme `name` strings such as "Charcoal" and "Terminal Split" are proper-noun labels copied verbatim from the web manifest and are not routed through a string catalogue; the file contains no other user-facing text.

## Accessibility Options

Not applicable: the file holds fixed colour and font values and does not read Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the catalogue is unconditional; no flag gates any theme.

## Analytics

Not applicable: the file emits no events.

## Privacy

Not applicable: the file holds no user data, credentials or tokens; it stores nothing and transmits nothing.

## Logging

Not applicable: the file contains no log calls.

## Platform Notes

- **SwiftUI**: Source is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/BuiltInThemes+Web.swift`, an `extension BuiltInThemes` of static `ColorTheme` constants built with `RGBAColor(hexString:)`. Native adjustments are in `BuiltInThemes+Native.swift` and the tests are in `PortedThemeTests.swift`. The data is made of value types, so reads need no actor isolation.
- **Compose**: Port each theme to a Kotlin `data class` and pass colours as `Color(0xAARRGGBB)`; Android hex is alpha-first while the source is `#RRGGBBAA`, so swap the channel order when converting. Keep the list as a top-level `val` and expose the type styles as `TextStyle` values with `fontFamily`, `fontWeight` and a `fontSize` multiplied by the scale.
- **React/Web**: These themes originate as CSS custom properties (`--pc-persona-bg`, `--color-accent`, `--pc-font`, `--font-mono`) in `packages/web/packages/themes/src/styles/*.css`; the web stylesheets keep the gradients and full font stacks that this port reduces to a first stop and a first family. A TypeScript port would be a typed record per theme, with colours as `#RRGGBBAA` strings or CSS custom properties.
- **AppKit / UIKit**: Resolve the colours to `NSColor` or `UIColor` through the SDK's `RGBAColor` converters, and the typography to `NSFont` or `UIFont` by family name, falling back to the system face (a monospaced system font when `monospaced` is true) when the family is not installed. `ToolkitFonts.registerBundledFonts()` is called before every font lookup and registers the faces the framework ships, which today is only `VT323-Regular`, at process scope through `CTFontManagerRegisterFontsForURL`. VT323 therefore resolves everywhere, while every other named family (Iosevka, Inter, Manrope and the rest) resolves only where the host has installed it and otherwise takes the system fallback.
- **WinUI 3**: Model each theme as an immutable C# record, with `Windows.UI.Color` values parsed from `#RRGGBBAA` strings (`Color.FromArgb` takes alpha first, so reorder the bytes). Expose the list as `IReadOnlyList<ColorTheme>` and publish the colours as `SolidColorBrush` entries in a `ResourceDictionary` that is swapped per theme; `ThemeDictionaries` keys are only `Light`, `Dark` and `HighContrast`, so a custom theme is a merged dictionary replaced at runtime rather than a new theme key. Bundle fonts such as VT323 with the package and reference them as `FontFamily="ms-appx:///Assets/Fonts/VT323.ttf#VT323"`. Whimsical's solid fill is a `SolidColorBrush`; a `LinearGradientBrush` would restore the web gradient. Apply `sizeScale` by multiplying the `FontSize` of each style, or bind it through a converter.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/BuiltInThemes+Web.swift` | confirmed (1.0.0) |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |

## Design Decisions

**Decision**: Port only 21 of the web manifest's 39 themes, leaving out the eight `adh*` font variants and ten editor palettes.
**Rationale**: The font variants differ only in typography, a web font-loading concern with no Swift analogue. The editor palettes already ship in Swift as terminal themes with real ANSI palettes, and the web copies would be the worse duplicate.
**Approved**: pending

**Decision**: Fill `ansi` as a best-effort derivation from semantic colours instead of porting an ANSI palette.
**Rationale**: These are brand themes and web defines no ANSI colours for them. The array exists only to satisfy the terminal feature; the exact web values that drive chat live in `roleOverrides`.
**Approved**: pending

**Decision**: Override both bubble fills to fully transparent in the seven flat terminal themes instead of omitting them.
**Rationale**: The web CSS declares no fill and `.pc-bubble` draws no box. Leaving the roles to derive had given Old School Terminal a grey slab the website has never drawn. An explicit transparent value lets the chat view read the theme as a flat transcript line.
**Approved**: pending

**Decision**: Carry web body size as a `sizeScale` ratio against a 15px baseline, not as absolute point sizes.
**Rationale**: AppKit metrics are not CSS pixels (body is 13pt by default), so transcribing pixels would make every ported theme about a fifth larger than every Swift-native theme. A ratio preserves what each theme said relative to its siblings, including the CSS note that VT323 renders small and needs a bump.
**Approved**: pending

**Decision**: Reduce a gradient to its first colour stop and a font stack to its first family plus a monospaced flag.
**Rationale**: `ColorTheme` holds solid `RGBAColor` values and `FontStyle` holds one family and a flag. The first stop is deterministic and keeps the dominant hue; the doc comments record the loss.
**Approved**: pending

**Decision**: Keep native-only changes in `BuiltInThemes+Native.swift` rather than in the generated file.
**Rationale**: The generated file must not be hand-edited, and the web catalogue has no tokens for native chrome such as the selection fill and cards. Applying the changes over the generated values means a generator re-run cannot silently drop them.
**Approved**: pending

**Decision**: Keep `thinkingDoneText` out of Old School Terminal although it shares a phosphor palette with the two CRT themes.
**Rationale**: Its CSS does not declare `--pc-thinking-done-color`, and a green settled line on that theme, the one the test comments say olylo's chat wears (the app's first-launch default theme is Old School Terminal), read as a turn still running. Sharing a palette is not the same as sharing the answer to this question.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-platform-notes](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90c2d8c2-cf79-5465-bffd-54f9fb1453bc) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1888cb38-9583-5657-a76f-c9685d296d6c) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-change-history](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/14bf2d1d-875b-5e58-b43d-be492c9f941a) | passed | artifact-formatting |

`separation-of-concerns` passes: the file is pure data, with native-only changes kept in `BuiltInThemes+Native.swift` and role resolution in `SemanticPalette`. `unit-test-coverage` is `partial`: `PortedThemeTests` asserts the catalogue, palette validity, chat-role presence, flatness, typography, size scales and the settled-colour rule, but no test asserts the individual hex values, the ids or the ANSI slot rules. `explicit-error-handling` is `partial`: every colour is built with a force-unwrapped `RGBAColor(hexString:)`, so a malformed generated literal traps rather than returning an error. `no-hardcoded-strings` is `partial`: theme names are English proper nouns held as literals, with no string catalogue. `graceful-degradation` passes: absent optional roles derive, and the doc comments state that a missing font family falls back to the system face. The formatting checks pass for this recipe.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
