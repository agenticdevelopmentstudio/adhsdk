---
id: 76d3e5ac-b014-4ba1-a8a4-7bf61f38529b
title: Theme Engine
domain: adhsdk://recipes/theme-engine
type: ingredient
version: 1.0.2
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'Cross-platform theme engine: Apple''s derivable ColorTheme/SemanticPalette/ThemeStore
  vs. web''s static CSS theme catalog and AppearancePrefs layer.'
platforms:
- swift
- macos
- ios
- typescript
- web
tags:
- theming
- color
- typography
- persistence
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Theme Engine

## Overview

The theme engine is the shared, no-UI model behind every color scheme and text
style a host app offers. On Apple it is a fully structured, derivable model:
`ColorTheme` carries a 16-slot ANSI-style palette plus optional per-role
overrides and typography, `SemanticPalette` resolves that into ~40 named
`ThemeRole` colors (deriving anything not explicitly overridden), and
`ThemeStore` is the CRUD/import/export catalog of built-in and user themes,
persisted through a host-supplied `ThemeStorage` seam. On web the shape is
different: each theme is a complete, pre-authored CSS custom-property block
selected by string key (`manifest.ts` / `ThemeStyle.tsx`), and a separate,
much smaller `AppearancePrefs` model (color mode plus a handful of
accessibility preferences) is layered on top via document classes and
`data-*` attributes. There is no web equivalent of Apple's derivable palette,
custom-theme storage, or `.itermcolors`/JSON import — the two platforms solve
"give the user a theme" with genuinely different architectures, which is the
central fact this recipe records.

## Behavioral Requirements

### Color and palette model (Apple)

- **ansi-palette-validity**: `ColorTheme.hasValidPalette` MUST be `true` if
  and only if `ansi.count == ColorTheme.ansiColorCount` (16); `ColorTheme`'s
  memberwise initializer itself performs no such check.
- **ansi-color-lookup**: `ColorTheme.ansiColor(at:)` MUST return `ansi[index]`
  when `index` is within `ansi.indices` and MUST return `nil` otherwise
  (negative index or index `>= ansi.count`), never trap.
- **theme-lock-state**: `ColorTheme.isEditable` MUST equal
  `!isBuiltIn && !isImported`; `isLocked` MUST equal `!isEditable`;
  `isDeletable` MUST equal `!isBuiltIn`.
- **theme-decoding-defaults**: `ColorTheme.init(from:)` MUST decode
  `isBuiltIn`, `isImported`, `roleOverrides`, `typography`, `terminal` and
  `project` as their documented defaults (`false`, `false`, `[:]`, `.system`,
  `nil`, `nil`) when absent from the payload, so a theme persisted before a
  field existed still decodes.
- **rgba-component-clamping**: `RGBAColor.init(red:green:blue:alpha:)` MUST
  clamp every component into `[0, 1]` via `Swift.min(1, Swift.max(0, _))`,
  including a non-finite input (NaN clamps to `0`, `+infinity` to `1`,
  `-infinity` to `0`, per `ColorThemeTests`).
- **rgba-hex-codec**: `RGBAColor(hexString:)` MUST parse an 8-hex-digit
  `RRGGBBAA` string (an optional leading `#`, case-insensitive) and MUST
  return `nil` for any other length or non-hex content; `RGBAColor.hexString`
  MUST serialize as uppercase `#RRGGBBAA` (9 characters); `Codable`
  encode/decode MUST round-trip through this same hex string and MUST throw
  `DecodingError.dataCorruptedError` for an unparseable value.

### Semantic role derivation (Apple)

- **role-resolution-precedence**: `SemanticPalette.color(_:)` MUST return
  `theme.roleOverrides[role.rawValue]` when present and MUST otherwise return
  the value `SemanticPalette.derive(role:theme:)` computes.
- **role-declares-explicit**: `SemanticPalette.declares(_:)` MUST report
  `true` only when the theme has an explicit `roleOverrides` entry for that
  role, independent of whether the derived color would already look
  identical or be fully opaque.
- **background-elevation-derivation**: absent an override,
  `.windowBackground` MUST equal `background`; `.surface`, `.elevatedSurface`
  and `.controlBackground` MUST each be `background` blended toward
  `foreground` by `0.06`, `0.12` and `0.09` respectively.
- **text-emphasis-dimming**: absent an override, `.secondaryText`,
  `.tertiaryText` and `.placeholderText` MUST each be `foreground.dimmed(towards: background, by:, minContrast:)`
  with `(0.32, 3.0)`, `(0.55, 2.0)` and `(0.68, 1.6)` respectively;
  `.timestampText` MUST use `(0.55, 2.0)`.
- **status-accent-derivation**: absent an override, `.accent`, `.success`,
  `.warning`, `.danger` and `.info` MUST derive from `ansi[4]`, `ansi[2]`,
  `ansi[3]`, `ansi[1]` and `ansi[6]` respectively, falling back to
  `foreground` only when that ANSI index is out of range.
- **selection-and-cursor-passthrough**: absent an override, `.selection` MUST
  equal `theme.selection` and `.cursor` MUST equal `theme.cursor` exactly
  (no blending); `.selectionText` MUST be `theme.selection.bestTextColor()`.
- **chat-role-derivation**: absent overrides, the eleven `persona*`/`user*`/
  `chat*`/`send*` roles MUST derive per the fixed formulas in
  `SemanticPalette.derive(_:theme:)` (e.g. `.personaName` and
  `.chatInputFocus` both equal derived `.accent`; `.userBubble` is
  `background` blended `0.18` toward derived `.accent`; `.chatSurface`
  equals `background` unchanged).
- **thinking-status-derivation**: absent overrides, `.thinkingDoneText` MUST
  be `foreground.desaturated().dimmed(towards: background, by: 0.55, minContrast: 2.0)`
  and `.thinkingIdleText` MUST be
  `foreground.desaturated().dimmed(towards: background, by: 0.25, minContrast: 3.0)`;
  the two MUST remain distinct roles (never aliased to one another or to
  `.timestampText`).
- **chart-series-colors**: `chartSeriesColors` MUST order
  `[accent, success, info, warning, danger]` followed by
  `ansi[9], ansi[10], ansi[11], ansi[12], ansi[13], ansi[14]`, filtered to
  entries whose `contrastRatio(against: surface) >= 1.5`, and MUST fall back
  to the unfiltered five semantic colors when that filter empties the list
  (the result MUST NOT be empty).
- **identity-series-colors**: `identitySeriesColors` MUST draw from
  `ansi[5], ansi[6], ansi[13], ansi[14]`, excluding any color equal to
  `accent`/`success`/`warning`/`danger` or already collected, filtered to
  `contrastRatio(against: surface) >= 1.5`, and MUST fall back to
  `chartSeriesColors` when the result would otherwise be empty.
- **reader-scale-layering**: `SemanticPalette.scaled(by:)` MUST clamp its
  `factor` argument through `ThemeTypography.clampedSizeScale` before
  multiplying it into `readerScale`, MUST leave `theme` and the resolved
  color map untouched, and MUST return `self` unchanged when the clamped
  factor is `1`; `size(_:)` MUST return
  `theme.typography.size(role) * readerScale`.

### Typography (Apple)

- **font-style-shape**: `FontStyle` MUST carry `family: String?` (`nil` means
  the system font), `size: Double` (pre-scale), `weight: FontWeight` and
  `monospaced: Bool`.
- **text-role-default-metrics**: `ThemeTypography.defaultStyle(_:)` MUST
  return the fixed AppKit-metric-mirroring styles: title 22pt semibold,
  heading 15pt semibold, body 13pt regular, caption 11pt regular, code 12pt
  regular monospaced, button 13pt medium.
- **typography-role-resolution**: `ThemeTypography.style(_:)` MUST return
  `styles[role.rawValue]` when present, else `defaultStyle(role)`;
  `size(_:)` MUST return `style(role).size * sizeScale`.
- **size-scale-clamping**: `ThemeTypography.clampedSizeScale` MUST clamp its
  input into the closed range `0.5...4` inclusive; both
  `SemanticPalette.scaled(by:)` and `ThemeStore.importJSON` MUST route
  through this exact same function and range.

### Built-in theme catalog (Apple)

- **built-in-catalog-composition**: `BuiltInThemes.all` MUST equal
  `handAuthored + webPorted` in that order: 15 hand-authored themes
  (`BuiltInThemes.swift`) followed by 21 web-ported themes
  (`BuiltInThemes+Web.swift`), for 36 built-ins total.
- **default-theme-id**: `BuiltInThemes.defaultID` MUST equal Solarized
  Dark's fixed id (`"A1B2C3D4-0001-4000-8000-000000000001"`).
- **built-in-lookup**: `BuiltInThemes.theme(withID:)` MUST return the first
  entry of `all` whose `id` matches, or `nil` if none matches.
- **built-in-hex-fail-fast**: the private `rgb(_:)` helper MUST append `"FF"`
  to a bare `"rrggbb"` literal (stripping any leading `#`) and MUST call
  `preconditionFailure` — trapping the process, not throwing or returning a
  placeholder color — when the resulting 8-hex-digit string fails to parse.
- **web-ported-theme-provenance**: the 21 `webPorted` themes MUST be
  generated output of `scripts/generate_web_theme_swift.py` from
  `scripts/extract_web_themes.py`, covering exactly 21 of the web
  manifest's 39 theme keys; the 8 `adh*` font-variant keys and the 10 web
  keys that duplicate an already-hand-authored Swift terminal theme
  (`dracula`, `nord`, `gruvbox`, `solarized`, `catppuccin`, `github`,
  `monokai`, `one-dark`, `tokyo-night`, `rose-pine`) MUST NOT be ported.

### Theme store contract (Apple)

- **catalog-composition**: `ThemeStore.allThemes` MUST equal
  `BuiltInThemes.all + customThemes` (built-ins always first, in
  `BuiltInThemes.all`'s own order).
- **built-in-membership-check**: `ThemeStore.isBuiltIn(id:)` MUST check only
  `BuiltInThemes.theme(withID:)`, never `customThemes`.
- **add-persists-custom**: `ThemeStore.add(_:)` MUST append the theme to
  `storage.customThemes` and MUST return the same theme unchanged.
- **update-scoped-to-custom**: `ThemeStore.update(_:)` MUST replace the
  `customThemes` entry sharing the theme's `id` and MUST be a no-op (no
  storage write, no error) when no such entry exists, including when `id`
  belongs to a built-in.
- **delete-clears-active**: `ThemeStore.delete(id:)` MUST remove the
  matching `customThemes` entry (a no-op for a built-in id) and MUST also
  set `storage.activeThemeID = nil` when `id` was the active theme, so
  storage never keeps pointing at a theme that no longer exists.
- **name-disambiguation**: `uniqueName(_:)` MUST append `" 2"`, `" 3"`, …
  (scanning names across all of `allThemes`, not just `customThemes`) until
  it produces a name no existing theme already has.
- **add-new-theme-seeding**: `ThemeStore.addNewTheme(basedOn:name:)` MUST
  copy `template` (default `BuiltInThemes.solarizedDark`), assign a fresh
  `UUID().uuidString` id, a disambiguated name, force `isBuiltIn = false`
  and `isImported = false`, clear `attribution` to `nil`, then persist it
  via `add(_:)`.
- **duplicate-always-unlocked**: `ThemeStore.duplicate(_:nameSuffix:)` MUST
  work on any theme (built-in, imported or custom), assign a fresh id and a
  disambiguated `name + nameSuffix`, and MUST force `isBuiltIn = false` and
  `isImported = false` regardless of the source theme's lock state.
- **import-format-sniffing**: `ThemeStore.importTheme(contentsOf:)` MUST
  choose the JSON parser when the file's first non-whitespace byte is `0x7B`
  (`{`) and MUST otherwise use the `.itermcolors` parser — by content, never
  by file extension.
- **import-forces-lock-and-identity**: `importITermColors`, `importJSON` and
  `importTheme` MUST set `isImported = true`, `isBuiltIn = false` and assign
  a fresh `UUID().uuidString` id on every successful import, discarding any
  id the source data carried.
- **import-palette-validation**: `ThemeStore.importJSON(data:)` MUST throw
  `ThemeImportError.invalidPalette(count:)` when the decoded theme's
  `ansi.count != ColorTheme.ansiColorCount` and MUST throw
  `ThemeImportError.foregroundMatchesBackground` when
  `foreground == background`; on either failure `storage.customThemes` MUST
  be left unchanged (nothing persisted).
- **import-scale-repair**: `ThemeStore.importJSON(data:)` MUST clamp the
  decoded theme's `typography.sizeScale` through
  `ThemeTypography.clampedSizeScale` rather than rejecting the import for an
  out-of-range value.
- **export-json-format**: `ThemeStore.exportJSON(_:)` MUST encode with
  `JSONEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]`.

### Storage and persistence (Apple)

- **storage-seam-contract**: a `ThemeStorage` conformer's `customThemes` and
  `activeThemeID` MUST round-trip (a value written through the setter MUST
  be what a subsequent read of the same property returns); built-in themes
  MUST NOT be written to storage — `ThemeStore` concatenates them at read
  time.
- **external-change-notification**: `ThemeStorage.onExternalChange` MUST be
  invoked when `customThemes` or `activeThemeID` changes from a source other
  than the `ThemeStore`/`ThemeManager` write path through this same
  protocol.
- **userdefaults-roundtrip**: `UserDefaultsThemeStorage.customThemes` MUST
  encode/decode as JSON `Data` under the key `"theme.custom_themes"`;
  `activeThemeID` MUST read/write a plain string under
  `"theme.active_theme_id"`.
- **userdefaults-decode-fallback**: `UserDefaultsThemeStorage.customThemes`'s
  getter MUST return `[]` (never throw) when the stored `Data` fails to
  decode as `[ColorTheme]`.
- **external-change-detection**: `UserDefaultsThemeStorage` MUST record the
  value it is about to write into `lastSeenThemes`/`lastSeenActiveID`
  *before* performing the `UserDefaults.set` call, and its
  `UserDefaults.didChangeNotification` handler MUST fire
  `onExternalChange` only when the current stored value differs from that
  last-seen value (so the object's own synchronous write never re-triggers
  itself).
- **observer-lifecycle**: `UserDefaultsThemeStorage.init` MUST register
  exactly one `NotificationCenter` observer for
  `UserDefaults.didChangeNotification` scoped to its `defaults` instance,
  and `deinit` MUST remove it.
- **main-actor-isolation**: `ThemeStorage`, `ThemeStore` and
  `UserDefaultsThemeStorage` are declared `@MainActor`; a caller off the
  main actor MUST hop onto it (`await`/`MainActor.run`) before touching any
  of their members — this is stated by the declaration itself, not left
  ambiguous. `ColorTheme`, `RGBAColor`, `ThemeRole`, `TextRole`, `FontStyle`,
  `ThemeTypography` and `SemanticPalette` are `Sendable` value types and MAY
  be read or copied from any isolation domain without synchronization.

### iTerm color import (Apple)

- **itermcolors-required-keys**: `ITermColorsParser.parse` MUST throw
  `.notADictionary` when the plist root is not `[String: Any]`, MUST throw
  `.missingColor(key)` when `"Foreground Color"`, `"Background Color"` or
  any of `"Ansi 0 Color"`…`"Ansi 15 Color"` is absent, and MUST throw
  `.missingComponent(colorKey:component:)` when a present color entry lacks
  its `"Red Component"`, `"Green Component"` or `"Blue Component"` (alpha is
  optional and defaults to `1.0`).
- **itermcolors-fg-ne-bg**: `ITermColorsParser.parse` MUST throw
  `.foregroundMatchesBackground` when the parsed foreground and background
  colors are equal, before constructing a `ColorTheme`.
- **itermcolors-optional-fallbacks**: `cursor` MUST fall back to the parsed
  `foreground` and `selection` MUST fall back to
  `background.blended(withFraction: 0.25, of: foreground)` when their
  respective plist keys are absent (only these two keys tolerate absence).
- **itermcolors-appearance-inference**: when `appearance` is not supplied,
  the resulting theme's `appearance` MUST be `.dark` when `background.isDark`
  is `true` and `.light` otherwise.
- **itermcolors-default-name**: `parse(contentsOf:name:...)` MUST default
  `name` to the file's base filename with its extension stripped when `name`
  is `nil`.

### Color math (Apple)

- **luminance-and-darkness**: `RGBAColor.relativeLuminance` MUST compute the
  WCAG sRGB relative luminance (linearization threshold `0.03928`, gamma
  `2.4`, channel weights `0.2126/0.7152/0.0722`); `isDark` MUST be
  `relativeLuminance < 0.5`.
- **contrast-ratio-formula**: `contrastRatio(against:)` MUST compute
  `(lighter + 0.05) / (darker + 0.05)` from the two relative luminances and
  MUST be symmetric; the type provides no compositing guard, so a caller
  comparing a translucent color MUST composite it over its real backdrop
  first via `composited(over:)`.
- **alpha-compositing**: `composited(over:)` MUST perform source-over alpha
  compositing and MUST return fully transparent black
  (`red/green/blue/alpha == 0`) when the resulting output alpha is `<= 0`.
- **best-text-color**: `bestTextColor(black:white:)` MUST return whichever
  of its two arguments (default opaque black/white) has the greater-or-equal
  `contrastRatio(against: self)`, ties resolving to `white`.
- **desaturation-formula**: `desaturated(by:)` MUST blend the color toward
  its own Rec. 601 luma-grey (`0.299/0.587/0.114` over the encoded sRGB
  channels, not linear `relativeLuminance`) by `amount` clamped to `[0, 1]`,
  defaulting to full desaturation (`amount == 1`).
- **contrast-floor-dimming**: `dimmed(towards:by:minContrast:)` MUST start
  at the requested blend `fraction` and step the blend amount down in
  `0.05` increments until `contrastRatio(against: background) >= minContrast`
  is satisfied, and MUST return the original, un-blended color unchanged if
  no amount down to `0` satisfies that floor (the floor is a best-effort
  ceiling on darkening, not a guarantee that it is met).

### Appearance preferences (Web)

- **appearance-prefs-shape**: `AppearancePrefs` MUST carry `colorMode`
  (`"auto" | "light" | "dark"`), `reduceMotion` (`"auto" | "on" | "off"`),
  `contrast` (`"default" | "high" | "extra-high"`), `textSize`
  (`"default" | "small" | "large" | "extra-large"`), `spacing`
  (`"compact" | "comfortable" | "spacious"`), `focusOutlines: boolean` and
  `underlineLinks: boolean`; `APPEARANCE_DEFAULTS` MUST be
  `{auto, auto, default, default, compact, false, false}`.
- **appearance-sanitization**: `normalizeAppearance(raw)` MUST start from a
  fresh copy of `APPEARANCE_DEFAULTS` and MUST overwrite a field only when
  `raw`'s corresponding property is one of that field's exact known literal
  values (or a `boolean` for the two boolean fields); an unrecognized value,
  a non-object `raw`, or a falsy `raw` MUST leave the defaults for that
  field (or all fields) untouched.
- **appearance-storage-roundtrip**: `readStoredAppearance` MUST read
  `localStorage["adh:appearance"]`, `JSON.parse` it and pass the result
  through `normalizeAppearance`, returning `APPEARANCE_DEFAULTS` when
  `window` is undefined (SSR) or when reading/parsing throws;
  `writeStoredAppearance`/`clearStoredAppearance` MUST likewise swallow a
  thrown storage error (private mode, quota) as a silent no-op.
- **appearance-dom-application**: `applyAppearance(el, prefs, systemPrefersDark)`
  MUST toggle the `dark` class using `systemPrefersDark` only when
  `prefs.colorMode === "auto"` (otherwise the literal mode), MUST always set
  `el.dataset.colorMode`, and for `reduceMotion`/`contrast`/`textSize`/
  `spacing` MUST set the matching `data-*` attribute to the value or
  *remove* the attribute entirely when the value equals that field's own
  default; `focusOutlines`/`underlineLinks` MUST set their attribute to
  `"always"` when `true` and remove it when `false`.
- **appearance-prepaint-script**: `APPEARANCE_PREPAINT_SCRIPT` MUST be
  generated from the same `ENUM_PREF_DEFAULTS`/`BOOL_PREFS` tables
  `applyAppearance` iterates and MUST run inside a `try/catch`. An absent
  stored value, or one that parses to a non-object, resolves to
  `colorMode: "auto"` (falling through to
  `matchMedia("(prefers-color-scheme: dark)")`); its `JSON.parse` call has
  no fallback, though, so a stored value that is present but fails to parse
  — or one that parses to the JSON literal `null`, which passes the
  script's `typeof === "object"` guard and then throws when it reads
  `p.colorMode` — throws inside the `try` and is swallowed by the empty
  `catch`, leaving `<html>` with neither the `dark` class nor
  `data-color-mode` set at all (see Edge Cases).
- **appearance-external-store**: `useAppearancePreferences` MUST be backed
  by a single module-level store consumed through `useSyncExternalStore`
  (not React Context); `commit(next, cache)` MUST update the module-level
  `current`, MUST persist to `localStorage` only when `cache` is `true`,
  MUST re-apply to `document.documentElement` when `document` is defined,
  and MUST notify every subscribed listener.
- **appearance-media-probe**: the shared `prefers-color-scheme`
  `MediaQueryList` and its `addEventListener` registration MUST each be
  feature-probed (`typeof window.matchMedia === "function"`,
  `typeof mq.addEventListener === "function"`) at module scope, so import
  cannot throw in an environment lacking either API; such an environment
  MUST resolve `auto` color mode to light.
- **appearance-sign-in-adopt**: `adoptAppearance(prefs)` MUST call
  `commit(prefs, true)` unconditionally — the server-supplied preferences
  MUST overwrite whatever this browser had cached, with no merge.
- **appearance-sign-out-reset**: `resetAppearance()` MUST call
  `commit({...APPEARANCE_DEFAULTS}, false)`, which MUST clear (not merely
  leave stale) the `localStorage` cache, so the next visitor on a shared
  browser starts from the OS setting.

### CSS theme catalog (Web)

- **theme-key-catalog**: `themes: Record<ThemeKey, ThemeEntry>` MUST be a
  fixed, statically-imported map of all 39 `ThemeKey` values to
  `{id, label, css}`; `themeIds` MUST equal `Object.keys(themes)`.
- **theme-lookup-by-key**: `ThemeStyle({theme, scope, colorMode})` MUST look
  up `themes[theme]` and MUST render `null` (not throw) when the key is
  absent from the catalog.
- **theme-style-element-identity**: an unscoped `ThemeStyle` render MUST use
  the fixed element id `"adh-sdk-theme"`; a scoped render MUST use
  `"adh-sdk-theme-scoped-" + <scope, lowercased, with every run of
  non [A-Za-z0-9_-] characters and any leading/trailing "-" stripped>`.
- **css-scoping-rewrite**: `buildScopedCss(css, scope, colorMode)` MUST
  rewrite, in this precedence, the html:root-anchored light-only pattern,
  then any other html:root-qualified pattern, then bare `html:root`, then
  `:root.dark`, `:root:not(.dark)`, bare `:root`, then `body` — into
  `:scope`-relative selectors inside a generated
  `@scope (<scope>) { ... }` block, and MUST preserve every `@import` line
  verbatim, emitted ahead of the `@scope` block.
- **css-scoping-forced-mode**: when `colorMode` is `"light"` or `"dark"`,
  `buildScopedCss` MUST resolve the chosen variant's selector unconditionally
  to `:scope` and the other variant's to the never-matching selector
  `:scope.pc-colormode-off`; when `colorMode` is `"system"` (the default),
  both variants MUST remain keyed to `html.dark :scope` /
  `html:not(.dark) :scope` (and the html:root-anchored light block to
  `html[data-color-mode]:not(.dark) :scope`).
- **theme-style-inline-render**: `ThemeStyle` MUST render the resolved CSS
  via `dangerouslySetInnerHTML` on a `<style>` element (present in
  server-rendered HTML, updates reactively on re-render/HMR), never via an
  imperative DOM-mutation API.
- **token-parsing**: `parseRootProps(css)` MUST extract, in source order,
  every `--custom-property: value;` declaration inside the *first*
  `:root { ... }` block into a `Map<string, string>`; `splitImports(css)`
  MUST separate every `@import url(...)` statement from the remaining CSS.
- **font-preload-manifest**: `THEME_FONT_PRELOADS` MUST list
  `${manifest.publicPath}/${face.file}` for every face in
  `fonts/metrics.json` whose `preload` flag is set, and MUST omit every
  face without it.

### Legacy color mode (Web)

- **legacy-colormode-isolation**: `ColorModeProvider`/`useColorMode`
  (storage key `"adh-sdk:color-mode"`, attribute
  `data-appearance-mode`) is a second, independent color-mode system from
  `AppearancePrefs` (`"adh:appearance"`, `data-color-mode`); the two MUST
  NOT both be mounted on one document, since each independently toggles the
  document's `dark` class from its own state.
- **legacy-colormode-cycle**: `cycle()` MUST advance `mode` through the
  fixed sequence `auto → dark → light → auto`, reachable both by calling the
  hook's `cycle()` and by dispatching the `"awt:appearance-cycle"` window
  event; a resulting change MUST dispatch `"awt:appearance-changed"`.
- **legacy-colormode-persistence**: setting `mode` to `"auto"` MUST remove
  the storage key rather than writing the literal string `"auto"`, so a
  stored value is only ever `"light"` or `"dark"`.

## Appearance

Not applicable — this is a data model and persistence/derivation engine, not
a visual component.

## States

Not applicable — this is a data model and persistence/derivation engine, not
a visual component. Its one true state machine — `ColorMode`'s
`auto → dark → light → auto` cycle in `colorMode.tsx` — is captured under
Behavioral Requirements (`legacy-colormode-cycle`), not here.

## Accessibility

Not applicable — this is a data model and persistence/derivation engine, not
a visual component. The web `AppearancePrefs` model it exposes carries
several accessibility *preferences* (motion, contrast, text size); those are
documented under Accessibility Options below, since they are inputs this
engine stores and applies, not a UI surface of its own.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| theme-engine-001 | ansi-palette-validity, ansi-color-lookup | A `ColorTheme` built with a 16-entry `ansi` array; call `hasValidPalette`, `ansiColor(at: 0)`, `ansiColor(at: 15)`, `ansiColor(at: 16)`, `ansiColor(at: -1)` | `hasValidPalette == true`; index 0 and 15 return the corresponding colors; index 16 and -1 both return `nil` |
| theme-engine-002 | ansi-palette-validity, import-palette-validation | JSON for a theme whose `ansi` array has 10 entries, passed to `ThemeStore.importJSON(data:)` | `hasValidPalette == false` on the decoded value; the call throws `ThemeImportError.invalidPalette(count: 10)`; `store.customThemes` is unchanged (empty) |
| theme-engine-003 | theme-lock-state | `BuiltInThemes.dracula`, a `ThemeStore.importITermColors(contentsOf:)` result, and a plain `ThemeStore.addNewTheme()` result | Built-in: `isLocked && !isEditable && !isDeletable`. Imported: `isLocked && !isEditable && isDeletable`. New custom: `isEditable && !isLocked && isDeletable` |
| theme-engine-004 | rgba-component-clamping | `RGBAColor(red: .nan, green: 0.5, blue: .infinity, alpha: -.infinity)` | `red == 0`, `green == 0.5`, `blue == 1`, `alpha == 0` |
| theme-engine-005 | rgba-hex-codec | `RGBAColor(hexString: "#FF00FFCC")`, then read `.hexString`; also `RGBAColor(hexString: "FF00FF")` (6 digits) | First call succeeds and `.hexString == "#FF00FFCC"`; second call returns `nil` (wrong length) |
| theme-engine-006 | role-resolution-precedence, role-declares-explicit | A theme with `roleOverrides[ThemeRole.accent.rawValue] = <purple>` vs. the same theme with no override for `.accent` | With the override: `palette.color(.accent) == <purple>` and `declares(.accent) == true`. Without it: `color(.accent) == ansi[4]` (or `foreground` if out of range) and `declares(.accent) == false` |
| theme-engine-007 | background-elevation-derivation, text-emphasis-dimming | `SemanticPalette(theme: BuiltInThemes.solarizedDark)` with no `.surface`/`.secondaryText` overrides | `palette.surface == background.blended(withFraction: 0.06, of: foreground)`; `palette.secondaryText == foreground.dimmed(towards: background, by: 0.32, minContrast: 3.0)` |
| theme-engine-008 | status-accent-derivation | `SemanticPalette(theme: t)` where `t.ansi[2]` is a known green and no `.success` override exists | `palette.success == t.ansi[2]` |
| theme-engine-009 | selection-and-cursor-passthrough | `SemanticPalette(theme: t)` where `t.selection`/`t.cursor` are known colors and no `.selection`/`.cursor` overrides exist | `palette.selection == t.selection`; `palette.cursor == t.cursor` |
| theme-engine-010 | chart-series-colors, identity-series-colors | A theme whose `ansi[5]`/`ansi[6]`/`ansi[13]`/`ansi[14]` are all equal to its own `.accent`/`.success`/`.warning`/`.danger` values (a degenerate monochrome-accent palette) | `identitySeriesColors` excludes every one of those slots (all "spoken") and falls back to `chartSeriesColors`; `chartSeriesColors` is non-empty |
| theme-engine-011 | reader-scale-layering, size-scale-clamping | `palette.scaled(by: 100)` then `.size(.body)`; separately `palette.scaled(by: 1)` | `scaled(by: 100)` clamps to `4` internally, so `size(.body) == theme.typography.size(.body) * 4`; `scaled(by: 1)` returns the identical `palette` instance |
| theme-engine-012 | typography-role-resolution, text-role-default-metrics | `ThemeTypography(styles: ["body": FontStyle(family: "Menlo", size: 17, weight: .bold)])` | `.style(.body).family == "Menlo"`, `.size == 17`, `.weight == .bold`; `.style(.title) == ThemeTypography.defaultStyle(.title)` (22pt semibold, unset) |
| theme-engine-013 | built-in-catalog-composition, default-theme-id, built-in-lookup | `BuiltInThemes.all.count`; `BuiltInThemes.theme(withID: BuiltInThemes.defaultID)?.name`; `BuiltInThemes.theme(withID: "not-a-real-id")` | `count == 36`; name is `"Solarized Dark"`; unknown id lookup returns `nil` |
| theme-engine-014 | catalog-composition, add-persists-custom, built-in-membership-check | Fresh `ThemeStore` over empty storage; call `add(customTheme)` | `store.allThemes.count == BuiltInThemes.all.count + 1`; `store.customThemes == [customTheme]`; `store.isBuiltIn(id: BuiltInThemes.defaultID) == true`, `store.isBuiltIn(id: customTheme.id) == false` |
| theme-engine-015 | update-scoped-to-custom | `store.update(theme)` for a `theme.id` matching a custom entry vs. `store.update(builtInCopy)` for a built-in's id | First call replaces the matching custom entry (name/fields updated). Second call is a no-op — `store.allThemes` unchanged, no built-in mutated |
| theme-engine-016 | delete-clears-active | `store` with `storage.activeThemeID == custom.id`; call `store.delete(id: custom.id)` | `store.theme(withID: custom.id) == nil`; `storage.activeThemeID == nil` afterward |
| theme-engine-017 | name-disambiguation, add-new-theme-seeding | Call `store.addNewTheme(name: "New Theme")` three times in a row | Names are `"New Theme"`, `"New Theme 2"`, `"New Theme 3"`, each `isEditable`, each a distinct id |
| theme-engine-018 | duplicate-always-unlocked | `store.duplicate(BuiltInThemes.dracula)` | Result has a fresh id (`!= dracula.id`), name `"Dracula Copy"`, `isBuiltIn == false`, `isEditable == true`, `ansi == BuiltInThemes.dracula.ansi` |
| theme-engine-019 | import-format-sniffing, import-forces-lock-and-identity | A `Data` value beginning with `{` (JSON) vs. one beginning with `<?xml` (a plist) passed to `importTheme(contentsOf:)` (via a temp file) | JSON bytes route through `importJSON`; plist bytes route through `importITermColors`; either result has `isImported == true`, `isBuiltIn == false`, and a fresh id different from any id embedded in the source data |
| theme-engine-020 | import-palette-validation | Valid-palette JSON whose `foreground` and `background` are the identical hex value, passed to `importJSON(data:)` | Throws `ThemeImportError.foregroundMatchesBackground`; `store.customThemes` is unchanged |
| theme-engine-021 | import-scale-repair | JSON declaring `"typography": {"sizeScale": 0, ...}` (a 16-color valid palette, distinct fg/bg), passed to `importJSON(data:)` | Import succeeds; the stored theme's `typography.sizeScale == 0.5` (clamped floor), not rejected |
| theme-engine-022 | export-json-format | `store.exportJSON(theme)` | Output is valid UTF-8 JSON whose top-level object keys are lexicographically sorted and whose formatting is multi-line/indented (pretty-printed) |
| theme-engine-023 | userdefaults-roundtrip, userdefaults-decode-fallback | Write `["theme.custom_themes": <malformed non-JSON Data>]` directly into a `UserDefaults` suite, then construct `UserDefaultsThemeStorage(defaults:)` and read `.customThemes` | Returns `[]`, does not throw |
| theme-engine-024 | external-change-detection | Two `UserDefaultsThemeStorage` instances sharing one `UserDefaults` suite; instance A sets `customThemes = [x]`; instance B's `onExternalChange` is observed | B's `onExternalChange` fires exactly once for A's write, and A's own `onExternalChange` (if attached) does NOT fire for its own write |
| theme-engine-025 | itermcolors-required-keys | A plist missing the `"Ansi 7 Color"` key (all other required keys present) | `ITermColorsParser.parse` throws `.missingColor("Ansi 7 Color")` |
| theme-engine-026 | itermcolors-fg-ne-bg, itermcolors-optional-fallbacks | A plist whose `"Foreground Color"` and `"Background Color"` are both `{R:0,G:0,B:0}` (no `Cursor`/`Selection` keys) | Throws `.foregroundMatchesBackground` before the cursor/selection fallback is ever reached |
| theme-engine-027 | itermcolors-appearance-inference, itermcolors-default-name | A well-formed `Dracula.itermcolors` (dark background) file parsed with `appearance: nil, name: nil` | Result `appearance == .dark`; `name == "Dracula"` |
| theme-engine-028 | contrast-ratio-formula, alpha-compositing | `RGBAColor.opaqueBlack.contrastRatio(against: .opaqueBlack)`; a 50%-alpha white composited `over: .opaqueBlack` | Contrast ratio `== 1.0` (identical colors); composited result is opaque mid-gray (`alpha == 1`, `red/green/blue ≈ 0.5`) |
| theme-engine-029 | best-text-color, desaturation-formula | `RGBAColor(hexString: "#00FF41FF")!.bestTextColor()`; the same color's `.desaturated(by: 1)` | `bestTextColor()` returns opaque black (higher contrast against bright green than white); `desaturated(by: 1)` yields an equal-luma neutral gray, not white or black |
| theme-engine-030 | contrast-floor-dimming | `foreground.dimmed(towards: background, by: 0.9, minContrast: 21)` where `foreground`/`background` have a real contrast well under 21 | Returns `foreground` unchanged (no amount from `0.9` down to `0` can reach a contrast of `21` against most real palettes) |
| theme-engine-031 | appearance-sanitization | `normalizeAppearance({colorMode: "purple", textSize: "large", focusOutlines: "yes"})` | `colorMode` stays `"auto"` (invalid literal rejected), `textSize` becomes `"large"` (valid), `focusOutlines` stays `false` (wrong type rejected) |
| theme-engine-032 | appearance-dom-application | `applyAppearance(el, {...defaults, textSize: "large", focusOutlines: true}, false)` | `el.dataset.textSize === "large"`; `el.dataset.focusOutlines === "always"`; `el.dataset.contrast` and `el.dataset.spacing` are both *absent* (equal their defaults) |
| theme-engine-033 | appearance-sign-in-adopt, appearance-sign-out-reset | Call `adoptAppearance({...defaults, colorMode: "dark"})`, then later `resetAppearance()` | After adopt: `localStorage` holds the dark-mode prefs. After reset: `localStorage["adh:appearance"]` is removed entirely and the live snapshot equals `APPEARANCE_DEFAULTS` |
| theme-engine-034 | theme-lookup-by-key, theme-style-element-identity | `render(<ThemeStyle theme="not-a-real-theme" />)`; `render(<ThemeStyle theme="dracula" scope="#a" />)` and `scope="#b"` | Unknown key: no `<style>` element rendered, no throw. Two scopes: two distinct `<style id="adh-sdk-theme-scoped-…">` elements with different ids |
| theme-engine-035 | css-scoping-forced-mode | `buildScopedCss(css, "#s", "dark")` vs. `buildScopedCss(css, "#s", "light")` for the same input `css` | The two outputs differ; the `"dark"` output contains `:scope` where the light block was and `:scope.pc-colormode-off` where the dark block was inverted, and vice versa for `"light"` |
| theme-engine-036 | legacy-colormode-cycle, legacy-colormode-persistence | `useColorMode()` starting at `mode: "light"`; call `cycle()` once, then again | First `cycle()`: `mode === "auto"`, storage key removed. Second `cycle()`: `mode === "dark"`, storage key set to `"dark"` |

## Edge Cases

- **Empty custom catalog**: `ThemeStore.allThemes` with an empty
  `storage.customThemes` MUST equal `BuiltInThemes.all` exactly (36 entries,
  no duplicates, no placeholder "no themes" entry).
- **Empty or short ANSI array on a hand-constructed theme**: nothing in
  `ColorTheme`'s memberwise initializer enforces `ansi.count == 16` (only
  `ThemeStore.importJSON` does). `ansiColor(at:)` bounds-checks and returns
  `nil` for any out-of-range index, so `SemanticPalette.derive` degrades to
  its `?? foreground` fallback for `.accent`/`.success`/`.warning`/`.danger`/
  `.info` rather than trapping. MUST NOT crash on an under-sized palette.
- **Boundary `sizeScale` values**: `0.5` and `4.0` themselves MUST pass
  `clampedSizeScale` unchanged (the range is closed/inclusive); `0.49999`
  and `4.00001` MUST clamp to `0.5` and `4.0` respectively.
- **Exactly-matching foreground/background**: both `ITermColorsParser.parse`
  and `ThemeStore.importJSON` MUST reject this case
  (`.foregroundMatchesBackground` / `ThemeImportError.foregroundMatchesBackground`)
  rather than admit an unreadable theme; a hand-constructed `ColorTheme` in
  Swift code is not stopped from doing this, since only the two import paths
  validate it.
- **Concurrent access — same process (Apple)**: `ThemeStore`,
  `ThemeStorage` and `UserDefaultsThemeStorage` are all `@MainActor`, so
  every call from within one process is serialized on the main actor; a
  `ThemeStore.add(_:)`'s internal read-then-write of
  `storage.customThemes` MUST NOT be interleaved with another same-process
  call, since neither suspends between the read and the write.
- **Concurrent access — cross-process (Apple)**: `UserDefaultsThemeStorage` detects an external
  change by comparing the current `UserDefaults` value against the value it
  itself last wrote or saw, and `ThemeStore.add`/`update`/`delete` perform a
  plain read-the-whole-array/write-the-whole-array cycle. Two writers
  sharing one `UserDefaults` suite (an app-group extension, another device
  via an iCloud-synced default) racing between one's read and its write can
  silently lose one side's change — `onExternalChange` only fires *after*
  the fact to prompt a reload/repaint, it neither detects nor prevents the
  lost update. The source declares no conflict-resolution policy, so the
  last whole-array write wins.
- **Storage write failure (Apple)**: `ThemeStorage.customThemes`/`.activeThemeID` are non-throwing
  `{ get set }` properties, and every `ThemeStore` mutator
  (`add`/`update`/`delete`/`duplicate`/`addNewTheme`/`importJSON`/
  `importITermColors`) reports success unconditionally once the setter
  returns. What happens when a host-supplied `ThemeStorage` conformer fails
  to durably persist that write (disk full, an inaccessible App Group
  container, a sandbox violation) is not reported: the
  protocol has no channel to report failure back to the caller, so an
  `add(_:)` that appears to succeed can silently not survive a relaunch.
- **Malformed JSON on import (Apple)**: a syntactically invalid JSON
  payload passed to `ThemeStore.importJSON(data:)` MUST propagate the raw
  `DecodingError` `JSONDecoder().decode` throws — this is a different,
  undocumented-to-the-caller error type from the two explicit
  `ThemeImportError` cases the method otherwise throws for a
  structurally-valid-but-semantically-invalid theme.
- **Malformed or inaccessible browser storage (Web)**: `readStoredAppearance`,
  `writeStoredAppearance` and `clearStoredAppearance` MUST catch and
  silently swallow any thrown error (JSON parse failure, private-mode
  storage denial, quota exceeded) and behave as if storage were empty/absent
  (falling back to `APPEARANCE_DEFAULTS` on read; no-op on write/clear).
- **Malformed stored value read by the prepaint script (Web)**: Unlike
  `readStoredAppearance`, `APPEARANCE_PREPAINT_SCRIPT`'s inline `JSON.parse`
  has no fallback. A stored value that is present but fails to parse (e.g. a
  truncated write such as `"{"`), or one that parses to the literal `null`,
  throws inside the script's `try` and is swallowed by its empty `catch`, so
  neither the `dark` class nor `data-color-mode` is set on `<html>` on that
  first paint. Only once React mounts and `readStoredAppearance` runs its own
  fallback does the page settle on `APPEARANCE_DEFAULTS` (`colorMode: "auto"`),
  so a corrupt or `null` stored value produces a flash between the
  script's did-nothing first paint and the React store's corrected one.
- **Environment without `matchMedia` (Web)**: `appearance-store.tsx`'s
  module-scope probe of `window.matchMedia` and `addEventListener` MUST NOT
  throw on import in such an environment (e.g. a stripped-down test
  renderer); `auto` color mode MUST then resolve to light (no system signal
  available).
- **Unknown theme key (Web)**: `ThemeStyle` MUST render `null` for a
  `theme` prop absent from the `themes` catalog (a stale persisted choice or
  a typo), never throw and take down the surrounding page.
- **Offline / disconnected state**: Not applicable — none of the given
  sources perform network I/O; all persistence is local
  (`UserDefaults` on Apple, `localStorage` on web) and works identically
  with no network present. (`appearance-store.tsx`'s own comments describe
  a server-synced copy of the preferences reached through
  `GET`/`PUT /me/appearance`, but that sync implementation is not among the
  sources given to this recipe.)

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` | `any ThemeStorage` (Apple) | none — required | Host-supplied persistence seam `ThemeStore` reads/writes through; built-ins are never stored. |
| `defaults` | `UserDefaults` (Apple) | `.standard` | The suite `UserDefaultsThemeStorage` persists into; a host with an App Group passes its shared suite. |
| `BuiltInThemes.defaultID` | `String` constant (Apple) | Solarized Dark's id | The theme a host falls back to when `activeThemeID` is `nil`. |
| `ColorTheme.ansiColorCount` | `Int` constant (Apple) | `16` | The required length of a well-formed theme's `ansi` array. |
| `ThemeTypography.sizeScaleRange` | `ClosedRange<Double>` constant (Apple) | `0.5...4` | Shared clamp bound for both a reader's runtime text-size control and an imported theme's own declared `sizeScale`. |
| `APPEARANCE_STORAGE_KEY` | `string` constant (Web) | `"adh:appearance"` | `localStorage` key for the current appearance system. |
| `APPEARANCE_DEFAULTS` | `AppearancePrefs` constant (Web) | `{auto, auto, default, default, compact, false, false}` | The preference set a signed-out/never-configured visitor gets. |
| `ColorModeProviderProps.storageKey` | `string` (Web, legacy) | `"adh-sdk:color-mode"` | Storage key for the separate legacy color-mode system. |
| `ColorModeProviderProps.defaultMode` | `ColorMode` (Web, legacy) | `"auto"` | Initial mode before any stored value is read. |
| `ThemeStyleProps.colorMode` | `"system" \| "light" \| "dark"` (Web) | `"system"` | Forces a scoped theme's variant regardless of `html.dark`. |
| `ThemeStyleProps.scope` | `string \| undefined` (Web) | `undefined` | When set, renders the theme scoped under `@scope`; when unset, renders globally under the fixed id. |

## Deep Linking

Not applicable: `ColorTheme`, `SemanticPalette`, `ThemeStore` and the web
appearance/theme-catalog modules expose no URL, route or app-scheme surface
in the given sources — a theme is selected by in-process id/string key, not
navigated to.

## Localization

The given sources contain hardcoded, non-localized English user-facing
strings; none is routed through `NSLocalizedString`, `String(localized:)`,
or an `i18n`/`intl` library.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `ThemeImportError.invalidPalette` | "This theme has {count} ANSI colors; a valid theme needs exactly {ansiColorCount}." | `ThemeImportError.errorDescription` (Apple), surfaced to the user via `LocalizedError` |
| `ThemeImportError.foregroundMatchesBackground` | "This theme's foreground and background are the same color, so its text would be invisible." | `ThemeImportError.errorDescription` (Apple) |
| `TerminalCursorShape.block` | "Block  ▉" | `TerminalCursorShape.label` (Apple, `ThemeOptions.swift`) — a theme-adjacent, user-facing picker label |
| `TerminalCursorShape.hollowBlock` | "Hollow Block  ▢" | `TerminalCursorShape.label` (Apple) |
| `TerminalCursorShape.underline` | "Underline  _" | `TerminalCursorShape.label` (Apple) |
| `TerminalCursorShape.bar` | "Bar  \|" | `TerminalCursorShape.label` (Apple) |
| theme display names | "Solarized Dark", "Dracula", "Charcoal", … | `BuiltInThemes`/`manifest.ts` `name`/`label` fields — 36 Apple built-ins and 39 web catalog entries, all literal English strings |

## Accessibility Options

The web `AppearancePrefs` model (not the Apple side, which has no such
concept in the given sources) directly implements two of Rule 15's display
options as stored, applied preferences:

| Option | Behavior |
|--------|----------|
| Reduce Motion | `AppearancePrefs.reduceMotion` (`"auto" \| "on" \| "off"`) is stored and, when not `"auto"`, `applyAppearance` sets `data-reduce-motion` to `"on"`/`"off"` for a consuming stylesheet's `@media`-query override; `"auto"` removes the attribute so `prefers-reduced-motion` governs. |
| Increase Contrast | `AppearancePrefs.contrast` (`"default" \| "high" \| "extra-high"`) is stored and applied the same way via `data-contrast`; `"default"` removes the attribute so `prefers-contrast` governs. |
| Differentiate Without Color | Not applicable: no field in `AppearancePrefs`, and no equivalent preference on the Apple side, exists in the given sources for this option. |

## Feature Flags

Not applicable: no flag/toggle system (a `{{app_prefix}}.*`-style key, a
remote-config check, or any conditional gate on a named flag) appears
anywhere in the given sources — every behavior described above is
unconditional.

## Analytics

Not applicable: none of the given sources emits an analytics event or calls
an event-tracking API; theme selection and appearance changes are not
instrumented in these files.

## Privacy

- **Data collected**: on Apple, the user's custom/imported theme
  definitions (`ColorTheme` — names, colors, optional `attribution` string,
  typography) and the id of the active theme. On web, the `AppearancePrefs`
  object (color mode plus the accessibility/spacing preferences listed
  above) — no theme *content* is user-editable on web, since themes are
  static, pre-authored CSS.
- **Storage**: Apple persists through the host-supplied `ThemeStorage`
  seam; the one concrete implementation given (`UserDefaultsThemeStorage`)
  writes to `UserDefaults` (locally, on-device, or to a shared App Group
  suite the host configures). Web persists `AppearancePrefs` to the
  browser's `localStorage` as a client-side cache.
- **Transmission**: none of the given Apple sources transmits theme data off
  the device. On web, `appearance-store.tsx`'s own comments describe
  `localStorage` as a cache of a signed-in user's preferences that also live
  on a server reached via `GET`/`PUT /me/appearance`, and that
  `adoptAppearance`/`resetAppearance` are the two reconciliation points a
  consuming app's own sign-in/sign-out flow is expected to call — but the
  request code itself is not among the sources given to this recipe.
- **Retention**: an Apple custom/imported theme persists until
  `ThemeStore.delete(id:)` removes it or the host clears its `ThemeStorage`
  backing store directly. A web `localStorage` appearance cache persists
  until overwritten or until `resetAppearance()` (sign-out) explicitly
  calls `clearStoredAppearance()`.

## Logging

Not applicable: none of the given sources issues a log call (no
`Logger`/`os_log`/`print` on Apple, no `console.*` on web). Failures are
either thrown as typed errors (`ThemeImportError`, `ITermColorsParseError`,
`DecodingError`) or intentionally swallowed with an inline comment
(`/* ignore */`, `catch { }`) — see Edge Cases / Error States for exactly
which.

## Platform Notes

- **SwiftUI**: the given sources
  (`packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/*.swift`) are
  themselves the actual model — Foundation-only, with no `Color`/`Font`
  dependency. A SwiftUI layer reads `SemanticPalette.color(_:)`/`.size(_:)`
  and is responsible for its own `RGBAColor` → `Color(red:green:blue:opacity:)`
  and `FontStyle` → `Font` bridges, neither of which appears in these files.
- **Compose (Android/Kotlin)**: model `ColorTheme` as an immutable
  (`@Immutable`) data class using `androidx.compose.ui.graphics.Color` in
  place of `RGBAColor`, and port `SemanticPalette` as a plain resolver
  producing a `androidx.compose.material3.ColorScheme`-shaped role map;
  persist custom themes through `DataStore` (Preferences or a typed
  serializer) in place of `UserDefaults`/`ThemeStorage`, and surface
  external changes via a `StateFlow<ColorTheme>` in place of the
  `onExternalChange` callback.
- **React/Web**: the given sources
  (`packages/web/packages/themes/src/*`) are themselves the actual
  implementation — a static, pre-authored CSS custom-property catalog
  (`manifest.ts`/`ThemeStyle.tsx`) selected by string key, plus a small,
  separately-stored `AppearancePrefs` model (`appearance.ts`) applied via
  document `class`/`data-*` attributes and read through a
  `useSyncExternalStore` singleton (`appearance-store.tsx`) — a materially
  different architecture from Apple's structured, derivable
  `ColorTheme`/`SemanticPalette` pair, with no equivalent of `ThemeStore`'s
  import/export/custom-theme CRUD.
- **AppKit / UIKit**: the same Apple source files as the SwiftUI bullet
  back this layer too; a host bridges `RGBAColor` → `NSColor`/`UIColor`
  (e.g. `NSColor(srgbRed:green:blue:alpha:)`) and `FontStyle` →
  `NSFont`/`UIFont`, and observes `ThemeStorage.onExternalChange` to know
  when to reload and repaint (that binding/observation layer itself lives
  outside the given sources, in the toolkit's separate UI test target).
- **WinUI 3**: model `ColorTheme` as a plain C# record
  (`Windows.UI.Color` via `Color.FromArgb` in place of `RGBAColor`); give
  `SemanticPalette` a constructor that pre-resolves a
  `Dictionary<ThemeRole, Color>` exactly as `SemanticPalette.init` does, and
  expose the result as `SolidColorBrush` entries in a `ResourceDictionary`
  (swapped via `Application.Current.Resources.MergedDictionaries` or
  `RequestedTheme`) so a `{ThemeResource accentBrush}` binding survives a
  theme swap the way `palette.color(.accent)` does. Persist
  `customThemes`/`activeThemeID` via
  `Windows.Storage.ApplicationData.Current.LocalSettings` (the
  `ThemeStorage` seam's WinUI analogue), serializing with
  `System.Text.Json` in place of `JSONEncoder`/`JSONDecoder`. Resolve
  `ThemeTypography` roles onto `FontFamily`/`FontWeight`/`FontSize` on a
  `TextBlock`/`Style` rather than AppKit/SwiftUI's `Font`. None of the given
  sources performs network I/O, so there is no `HttpClient`/`Task`/`async`
  analogue to port here.

## Design Decisions

**Decision**: `thinkingDoneText` and `thinkingIdleText` are two distinct
`ThemeRole`s rather than one shared "dim status text" role, even though they
render identically in most themes.
**Rationale**: per the source's own comments, the two disagree on themes
that give one an explicit color and not the other (`crt-monitor`,
`handheld-communicator` set `thinkingDoneText` to their phosphor green while
leaving the idle line a dim, mostly-transparent green), and a monochrome
terminal palette has no grey to derive from for the idle line at all — a
shared role could not represent both "reporting on work just finished" and
"nothing to report" once a theme actually differentiates them.
**Approved**: pending

**Decision**: a reader's runtime text-size multiplier (`SemanticPalette.scaled(by:)`)
is kept as a separate `readerScale` layered on top of `theme.typography.sizeScale`,
rather than folding into one number.
**Rationale**: the two answer to different people — `sizeScale` is the theme
designer's own correction (e.g. `old-school-terminal` sets `1.0667` because
VT323 draws small for its point size, a property of the chosen typeface),
while `readerScale` is the person using the app adjusting a "Text Size"
control; collapsing them would mean switching themes silently changed the
reader's own accessibility setting.
**Approved**: pending

**Decision**: `BuiltInThemes.rgb(_:)` traps via `preconditionFailure` on a
malformed built-in hex literal instead of returning a placeholder color or
throwing a catchable error.
**Rationale**: built-in theme literals are static, hand-authored constants
validated by `BuiltInThemesTests`; a malformed one is a programmer error
caught at build/test time, not a runtime condition any caller could
meaningfully recover from, so failing fast is preferred over silently
shipping a wrong color.
**Approved**: pending

**Decision**: `ThemeStore.duplicate(_:nameSuffix:)` always produces an
unlocked (`isBuiltIn == false && isImported == false`) theme, regardless of
whether the source theme was a built-in or a locked import.
**Rationale**: duplication is the toolkit's only editing path for a locked
theme ("edit by duplicating," stated directly in `ColorTheme`'s doc
comments for both `isBuiltIn` and `isImported`), so a duplicate that
inherited the source's lock would leave the user with no way to ever edit
what they just created.
**Approved**: pending

**Decision**: an out-of-range `typography.sizeScale` on `ThemeStore.importJSON`
is silently clamped into range rather than rejected as an import error,
while an invalid `ansi` count or `foreground == background` on the same
import *is* rejected.
**Rationale**: per the source's own comment, a bad scale only mis-sizes text
(recoverable, still usable) while an invalid palette or invisible text
makes the theme genuinely unusable — the two invalid-input categories are
deliberately given different severities.
**Approved**: pending

**Decision**: `chartSeriesColors`/`identitySeriesColors` filter candidate
colors by `contrastRatio(against: surface) >= 1.5` but fall back to an
unfiltered list rather than ever returning empty.
**Rationale**: a low-contrast series color is still better than a caller
that has to special-case "no colors available" — two chart series sharing
one visually-similar color beats a chart that cannot render any series at
all.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | failed | Best Practices |

separation-of-concerns passes because the Apple model splits palette data
(`ColorTheme`), role derivation (`SemanticPalette`), catalog CRUD
(`ThemeStore`), and persistence (the host-supplied `ThemeStorage` seam), and
the web splits pre-authored theme CSS (`manifest.ts` / `ThemeStyle.tsx`) from
the separate `AppearancePrefs` layer. unit-test-coverage passes because the
Apple `Theme` test suite covers each of those pieces — including
`ThemeStoreTests` and `UserDefaultsThemeStorageTests` for the catalog and its
persistence — and the web `themes` package tests `ThemeStyle`,
`buildScopedCss`, and the rescued themes. data-integrity is partial because
`ThemeStore`'s mutators do a plain read-then-write of the whole
`customThemes` array, so two processes sharing one `UserDefaults` suite can
lose an update (see the cross-process edge case). explicit-error-handling
fails because `ThemeStorage`'s properties are non-throwing, so a failed
durable write is never reported to the `ThemeStore` caller (see the storage
write failure edge case).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Compliance rewritten against catalog checks; two absent-feature edge cases restated as facts rather than open questions |
| 1.0.2 | 2026-09-25 | Mike Fullerton | appearance-prepaint-script now describes JSON.parse's missing fallback (unparseable/null throws, caught silently); added matching Edge Case. |
