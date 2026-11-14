---
id: 02e566d2-7403-4584-948c-1b4fff05070d
title: "Theme Fonts"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "THEME_FONT_PRELOADS: the same-origin hrefs of the self-hosted Iosevka faces a page should preload, derived from the font manifest that the theme css also reads."
platforms:
  - typescript
  - web
tags:
  - theme
  - fonts
  - performance
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Theme Fonts

## Overview

Theme Fonts is the one export of `fonts.ts` in the themes package: `THEME_FONT_PRELOADS`, a read-only list of absolute, same-origin hrefs for the self-hosted Iosevka faces the adh theme ships. A page renders a `<link rel=preload>` for each so the browser starts the download while it is still parsing `<head>`, before any layout.

The module exists for the one thing CSS cannot express, telling the browser to fetch a font before layout. The `@font-face` rules themselves are emitted into the theme css by `scripts/build-tokens.mjs`. Both sides read the same manifest, `src/fonts/metrics.json`, written by `scripts/subset-fonts.py`, so a preload cannot point somewhere the css does not or name a file that no longer exists.

The source's doc comment says the list is consumed by a `ThemeStyle` component rendered in the `<head>` of every consuming site; in this repo the consumer is `AdhThemeStyle` in the adh package, which calls react-dom's `preload(href, { as: 'font', type: 'font/woff2', crossOrigin: 'anonymous' })` for each entry, and only when `usesBaseThemeFonts(DEFAULT_SITE_THEME)` is true, and that the bytes are placed at these paths by `materializeThemeFonts` (the package's `materialize-fonts.mjs`). The module is also published as the `./fonts` subpath export of the package.

## Behavioral Requirements

### Exports

- **preload-list-export**: The module MUST export `THEME_FONT_PRELOADS` as a read-only array of strings (`readonly string[]`).
- **single-export**: The module MUST export no other runtime value; the manifest is imported but not re-exported.
- **computed-at-load**: The list MUST be computed once when the module is evaluated, from the manifest imported at that time.

### Selection

- **preload-flag-filter**: The list MUST contain exactly the manifest faces whose `preload` flag is truthy, and no face whose flag is false.
- **manifest-order**: The list MUST keep the order in which the faces appear in the manifest `faces` array.
- **core-cuts-only**: The faces flagged for preload MUST be the three CORE cuts (regular 400, bold 700 and italic 400); the EXT cuts MUST NOT be flagged, because `unicode-range` already keeps them unfetched until a page paints a codepoint in their range.
- **italic-included**: The italic 400 CORE cut MUST be in the list, because the `SiteLanding` heading sets its accent word in italic above the fold.

### Href shape

- **href-format**: Each entry MUST be the manifest `publicPath`, a slash, then the face `file` (for example `/fonts/bb398da1/iosevka-400.woff2`).
- **same-origin**: Each entry MUST be a root-relative path beginning with a single slash; it MUST NOT carry a scheme or host, since the preload is only worth emitting because the fetch rides the connection that delivered the html.
- **woff2-only**: Each entry MUST end in `.woff2`.
- **css-agreement**: Each entry MUST appear as the url of an `@font-face` in the css of the default adh theme built from the same manifest (the css emitted by `scripts/build-tokens.mjs`, as asserted by the adh consumer test).
- **no-validation**: The module MUST NOT validate the manifest, check that files exist, or filter on the file name; correctness of paths rests on the manifest generator and on the consumer's tests.

### Side effects and concurrency

- **no-side-effects**: Importing the module MUST NOT touch the network, the file system or the document; it only reads the bundled manifest.
- **immutable-value**: The value is computed once and never mutated by the module, so concurrent readers see the same list. Module evaluation is single-threaded.

## Appearance

Not applicable — this is a list of font hrefs, not a visual component.

## States

Not applicable — this is a constant list, not a visual component.

## Accessibility

Not applicable — this is a list of font hrefs, not a visual component.

## Conformance Test Vectors

The module has no test file beside it. Vectors 1 to 5 come from the tests of its consumer in the adh package, `landingTypeScale.test.ts` (describe block "the first-load font contract"); the rest follow from the filter and map in the source and the committed manifest.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| fonts-001 | preload-flag-filter | Import `THEME_FONT_PRELOADS` (test "preloads at least the faces that carry a page layout") | length is greater than 0 |
| fonts-002 | same-origin, woff2-only | Every entry (test "preloads only same-origin woff2 paths") | matches `^/[^/]` and ends in `.woff2` |
| fonts-003 | css-agreement | Each entry against the css of the default adh theme (test "declares an @font-face for every preloaded face") | the css contains the entry wrapped in `url('...')` |
| fonts-004 | css-agreement | The css of the default theme (test "fetches no font from a third-party stylesheet") | it contains no `@import` statement |
| fonts-005 | no-validation | Each entry resolved by its file name against the themes package `src/fonts` directory (test "ships the preloaded bytes at the path it preloads") | the file exists for every entry |
| fonts-006 | preload-flag-filter, manifest-order, href-format | The committed manifest: publicPath `/fonts/bb398da1`, faces in order 400, 400-ext, 700, 700-ext, 400-italic, 400-italic-ext, flagged true, false, true, false, true, false | `["/fonts/bb398da1/iosevka-400.woff2", "/fonts/bb398da1/iosevka-700.woff2", "/fonts/bb398da1/iosevka-400-italic.woff2"]` |
| fonts-007 | core-cuts-only | The same manifest | no entry ends in `-ext.woff2` |
| fonts-008 | preload-flag-filter | A manifest in which no face has `preload` true | the list is empty |
| fonts-009 | href-format | A manifest with publicPath `/x` and one preloaded face file `a.woff2` | `["/x/a.woff2"]` |
| fonts-010 | no-validation | A preloaded face whose file is absent from disk | the href is still listed; no error is raised |

## Edge Cases

- **Empty selection**: When no face is flagged, the list MUST be empty; the module raises nothing. The adh consumer test asserts a non-empty list, which is where that case is caught.
- **Missing manifest or missing field**: The manifest is a static JSON import, so a missing file fails at build or bundle time. A face lacking `file` would produce the text `undefined` in its href, since nothing checks it; the generator is the guard.
- **Stale paths**: The `publicPath` embeds a revision. If the bytes are not copied to that path (the app did not call `materializeThemeFonts`), the preload and the inlined `@font-face` both return 404 while the page falls back to the metric-matched fallback; the source's doc comment states that nothing downstream notices.
- **Non-boolean `preload`**: The filter uses truthiness, so any truthy value selects the face.
- **Boundary values**: Not applicable; the module takes no input and has no numeric limits.
- **Concurrent access**: Not applicable; the value is built once at module load, never mutated, and JavaScript module evaluation is single-threaded.
- **Offline or network failure**: Not applicable to this module, which performs no I/O; a failed fetch of a listed href is the browser's concern, and the page keeps the fallback face.
- **Cancellation and timeouts**: Not applicable; nothing here is asynchronous.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `src/fonts/metrics.json` | JSON manifest | committed file | Supplies `publicPath`, `revision` and the `faces` array (`file`, `weight`, `style`, `preload`, `unicodeRange`); generated by `scripts/subset-fonts.py`, never edited by hand |
| `preload` (per face) | boolean | set by the generator | CORE cuts true, EXT cuts false |

The module takes no parameters, reads no environment variable and has no settings key.

## Deep Linking

Not applicable: the module only lists font hrefs and has no routes or URL schemes.

## Localization

Not applicable: the module has no user-facing strings.

## Accessibility Options

Not applicable: the module draws nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach it.

## Feature Flags

Not applicable: the source reads no flag; the list is unconditional.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the module collects and stores nothing, and its hrefs are same-origin so no font request goes to a third party.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: There is no preload step; bundle the faces as app resources, declare them under the `UIAppFonts` key of the Info.plist (or register with `CTFontManagerRegisterFontsForURL` at launch), and use `Font.custom`. Register the regular, bold and italic cuts early so first layout does not fall back; the EXT split is unnecessary because the system handles glyph coverage.
- **Compose**: Put the faces in `res/font` and build a `FontFamily` of `Font(R.font.x, FontWeight.Normal, FontStyle.Italic)` entries; resource fonts are available synchronously, so no preload list is needed. Downloadable fonts, if used, take the place of the same-origin rule.
- **React/Web**: The source platform. `src/fonts.ts` imports `./fonts/metrics.json` and exports the filtered, mapped list; `AdhThemeStyle` (adh package) calls react-dom `preload(href, { as: 'font', type: 'font/woff2', crossOrigin: 'anonymous' })` per entry, which emits a font preload link (fonts need the crossorigin attribute even when same-origin), and does so only when the site's default theme uses the base theme fonts. `materialize-fonts.mjs` copies the woff2 into `public/` from each `next.config`, and `build-tokens.mjs` emits the `@font-face` rules. The package exposes the module through its `./fonts` subpath and ships `src/fonts` in its `files`.
- **AppKit / UIKit**: Register bundled fonts through `ATSApplicationFontsPath` (macOS) or `UIAppFonts` (iOS), or `CTFontManagerRegisterFontsForURL`, then `NSFont(name:size:)` or `UIFont(name:size:)`. No preload step exists; registration at launch is the equivalent.
- **WinUI 3**: Ship the fonts as `Content` items under `Assets/Fonts` and reference them in XAML with the `FontFamily` property in the form `ms-appx:///Assets/Fonts/Iosevka-Regular.ttf#Iosevka`; WinUI 3 loads TrueType or OpenType, so convert the woff2 cuts to ttf or otf, one file per weight and style, and select them with `FontWeight` and `FontStyle`. There is no browser-style preload; to warm the faces before first layout, create an off-screen `TextBlock` with each `FontFamily` at app start, or load them through a `CanvasTextFormat` in Win2D. Expose the faces as a resource in `App.xaml` (`<FontFamily x:Key="ThemeMono">`) and use `x:Uid` or `ThemeResource` bindings so a theme change swaps them. Keep the manifest as a JSON file read with `System.Text.Json` at startup if the list of faces must stay generated.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/themes/src/fonts.ts` | confirmed (1.0.1) |

## Design Decisions

**Decision**: The preload list is derived from the same manifest the css build reads, with no hand-written paths.
**Rationale**: The module's header states a preload can then never point somewhere the css does not, nor carry a filename that no longer exists.
**Approved**: pending

**Decision**: Only the three CORE cuts, italic included, are preloaded; EXT cuts never are.
**Rationale**: CORE cuts carry a page's layout and the italic accent word of the landing heading sits above the fold. EXT cuts are fetched lazily by `unicode-range`, so preloading them would add bytes to every first paint.
**Approved**: pending

**Decision**: Preloads are same-origin, absolute paths.
**Rationale**: The browser then starts the fetch while parsing `<head>` on the connection that delivered the html, rather than after a third-party stylesheet is fetched and parsed, which is the difference between the webfont arriving before first paint and after it.
**Approved**: pending

**Decision**: The module does no validation of the manifest or of file presence.
**Rationale**: The generator owns the manifest and the consumer test in the adh package asserts shape, css agreement and file presence, so a second check here would duplicate it. The cost is that a missing byte file is silent in the page (see Stale paths in Edge Cases).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.performance.startup-impact](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/41f11fb7-abed-5c62-ae13-456da5874bb0) | passed | performance |
| [adc.check.performance.lazy-loading](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/93049d53-e8e2-5ea3-8a3a-9eb07e60d0e2) | passed | performance |

Separation of concerns passes: the module does one thing, listing preload hrefs, and leaves rule emission to the css build and file placement to `materializeThemeFonts`, with the manifest as the single shared fact. Unit-test coverage is partial: no test sits beside `fonts.ts`; the contract is asserted by the adh package's `landingTypeScale.test.ts`, and the generator's preload flags are tested in `subset-fonts_test.py` for the site cuts only. Startup impact and lazy loading pass because only the three CORE cuts are preloaded and the EXT cuts are left to `unicode-range`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
