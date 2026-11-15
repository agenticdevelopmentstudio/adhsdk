---
id: 231a7e9a-8c03-44b3-afaf-b71755e05c1d
title: "ITermColorsParser"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Parses an iTerm2 .itermcolors property list into a ColorTheme, failing fast on missing required colors and falling back for cursor and selection."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - parser
  - iterm2
  - color
depends-on:
  - 932449c9-b57f-4e2c-992a-1e27584742b6
  - ad5bae6b-0172-4cd4-a4b7-297eb58eb28d
  - 591d0b87-ce71-4b11-8642-149fc405cce9
related:
  - d15bba09-4574-4fd1-93a0-f7d2cccd04f2
references: []
approved-by: ""
approved-date: ""
---

# ITermColorsParser

## Overview

`ITermColorsParser` is a stateless, caseless `enum` that turns the bytes of an iTerm2 `.itermcolors` file into a `ColorTheme` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.color-theme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6)). An `.itermcolors` file is a property list (XML or binary) whose top-level dictionary maps color keys (`Ansi 0 Color` through `Ansi 15 Color`, `Foreground Color`, `Background Color`, `Cursor Color`, `Selection Color`) to dictionaries of `Red Component`, `Green Component`, `Blue Component` and `Alpha Component` reals in 0 to 1. The parser uses Foundation's `PropertyListSerialization` and has no third-party dependency.

The color math it relies on (`blended`, `isDark`, clamping) comes from `RGBAColor` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.rgba-color](cookbook:ad5bae6b-0172-4cd4-a4b7-297eb58eb28d)) and the `RGBAColor` theme extension ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.rgba-color-theme](cookbook:591d0b87-ce71-4b11-8642-149fc405cce9)); the formulas the parser's results depend on are restated in the requirements below. Use it to import a terminal color scheme as an app theme. The parser is strict about the foreground, background and 16 ANSI colors, and lenient about cursor, selection and alpha. It does no I/O of its own except the URL overload, which reads the file with `Data(contentsOf:)`.

## Behavioral Requirements

Public surface: `ITermColorsParser.parse(data:name:id:appearance:)`, `ITermColorsParser.parse(contentsOf:name:id:appearance:)`, and the error enum `ITermColorsParseError` (`Error`, `Equatable`) with cases `notADictionary`, `missingColor(String)`, `missingComponent(colorKey:component:)` and `foregroundMatchesBackground`.

- **parse-data-returns-theme**: `parse(data:name:id:appearance:)` MUST return a `ColorTheme` built from the plist bytes, with `name` set to the supplied name.
- **parse-data-accepts-xml-and-binary**: `parse(data:)` MUST accept both XML and binary property-list encodings, since it delegates decoding to `PropertyListSerialization` with `format: nil`.
- **id-default-fresh-uuid**: When `id` is not supplied, the theme's `id` MUST be a fresh `UUID().uuidString`; when supplied, the theme's `id` MUST equal the supplied string.
- **not-built-in**: The returned theme MUST have `isBuiltIn` equal to `false`.
- **imported-flag-untouched**: The parser MUST NOT mark the theme imported; `isImported` keeps the `ColorTheme` initializer default. The caller (`ThemeStore` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.theme-store](cookbook:d15bba09-4574-4fd1-93a0-f7d2cccd04f2)) `importITermColors`) sets it after parsing.
- **top-level-must-be-dictionary**: The parser MUST throw `ITermColorsParseError.notADictionary` when the decoded plist root is not a `[String: Any]` dictionary.
- **foreground-required**: The parser MUST throw `missingColor("Foreground Color")` when the top-level dictionary has no dictionary value under `Foreground Color`.
- **background-required**: The parser MUST throw `missingColor("Background Color")` when the top-level dictionary has no dictionary value under `Background Color`.
- **ansi-required**: The parser MUST read `Ansi 0 Color` through `Ansi 15 Color` (`ColorTheme.ansiColorCount`, 16) in index order and MUST throw `missingColor("Ansi N Color")` for the first absent index.
- **ansi-order-preserved**: The returned `ansi` array MUST hold exactly 16 colors, where element N is the color decoded from `Ansi N Color`.
- **component-required**: Within any required color dictionary, the parser MUST throw `missingComponent(colorKey:component:)` naming the color key and the first missing component among `Red Component`, `Green Component`, `Blue Component`, checked in that order.
- **component-type-strict**: A component present but not castable to `Double` (a plist `integer` is castable and is accepted) MUST be treated as missing and MUST throw `missingComponent`.
- **alpha-default-opaque**: When `Alpha Component` is absent or not a `Double`, the parser MUST use alpha `1.0` and MUST NOT raise an error. This differs deliberately from the red, green and blue components: a present but non-numeric `Red`, `Green` or `Blue Component` throws `missingComponent` (`component-type-strict`), while a present but non-numeric `Alpha Component` silently becomes `1.0`.
- **extra-keys-ignored**: Keys the parser does not read (for example `Color Space`, `Bold Color`, `Link Color`, `Cursor Text Color`) MUST be ignored.
- **channel-clamping**: Every decoded channel MUST be clamped to 0 to 1, because each color is built through the `RGBAColor` initializer, which clamps its components.
- **foreground-equals-background-rejected**: The parser MUST throw `foregroundMatchesBackground` when the decoded foreground and background `RGBAColor` values are equal (all four channels, after clamping).
- **degenerate-check-before-ansi**: The foreground/background equality check MUST run after both colors decode and before any ANSI color is read, so an equal pair is reported even when the ANSI colors are missing.
- **cursor-fallback**: When `Cursor Color` is absent or fails to decode for any reason, the parser MUST use the foreground color as the cursor color and MUST NOT throw.
- **selection-fallback**: When `Selection Color` is absent or fails to decode for any reason, the parser MUST use `background.blended(withFraction: 0.25, of: foreground)` as the selection color and MUST NOT throw. `blended(withFraction: f, of: o)` is a per-channel linear interpolation `self * (1 - f) + o * f` over red, green, blue and alpha, with `f` clamped to 0 to 1.
- **appearance-explicit-wins**: When `appearance` is non-nil, the theme's `appearance` MUST equal it exactly, including `.auto`.
- **appearance-inferred**: When `appearance` is `nil`, the theme's `appearance` MUST be `.dark` if `background.isDark` and `.light` otherwise. `isDark` is `relativeLuminance < 0.5` (strict), where `relativeLuminance = 0.2126 * R + 0.7152 * G + 0.0722 * B` over the WCAG sRGB-linearized channels (`c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4`). Alpha does not enter the calculation.
- **luminance-boundary-light**: A background whose relative luminance is exactly 0.5 MUST infer `.light`, because the dark test is a strict less-than.
- **appearance-ignores-alpha**: A translucent background MUST infer the same appearance as the same color made opaque.
- **foreground-alpha-distinct**: A foreground that differs from the background only in alpha MUST compare unequal and MUST be accepted.
- **url-overload-reads-file**: `parse(contentsOf:name:id:appearance:)` MUST read the file with `Data(contentsOf:)` and delegate to `parse(data:name:id:appearance:)` with the other arguments unchanged.
- **url-overload-default-name**: When `name` is `nil`, the URL overload MUST use the file's base name, `url.deletingPathExtension().lastPathComponent` (`Dracula.itermcolors` becomes `Dracula`).
- **fail-fast**: The parser MUST stop at the first structural error and MUST NOT return a partial theme.
- **foundation-errors-propagate**: Errors from `PropertyListSerialization` (undecodable bytes) and from `Data(contentsOf:)` (unreadable file) MUST propagate to the caller unchanged and are not wrapped in `ITermColorsParseError`.
- **concurrency**: All entry points MUST be static and stateless, pure apart from the URL overload's file read, so concurrent calls MAY run in parallel. Nothing in the source serialises or isolates them.
- **side-effects**: The data overload MUST have no side effect; the URL overload's only side effect is reading one file. The parser writes no files, makes no network calls, posts no notifications and logs nothing.

## Appearance

Not applicable — this is a file-format parser, not a visual component.

## States

Not applicable — this is a file-format parser, not a visual component.

## Accessibility

Not applicable — this is a file-format parser, not a visual component.

## Conformance Test Vectors

Vectors 001 to 009 derive from `ITermColorsParserTests` (Swift Testing suite `ITermColorsParser`). Vectors 010 to 021 are marked "Source": each gives an exact fixture and is implemented in `ITermColorsParserTests`. In every fixture below, "base" means the fixture described next. The base fixture builds a plist with all 16 ANSI colors plus `Foreground Color`, `Background Color`, and optional `Cursor Color` (0.9, 0.9, 0.9) and `Selection Color` (0.2, 0.2, 0.2).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| itermcolors-001 | parse-data-returns-theme, ansi-order-preserved, not-built-in | Test `parsesPalette`: foreground (1,1,1), background (0,0,0), `Ansi 5 Color` (1,0,0.5), rest black; name `Test` | `name == "Test"`; foreground is `RGBAColor(1,1,1,1)`; background `RGBAColor(0,0,0,1)`; `ansi.count == 16`; `ansi[5] == RGBAColor(1,0,0.5,1)`; `isBuiltIn == false` |
| itermcolors-002 | appearance-inferred | Test `infersDark`: foreground white, background black, no `appearance` | `appearance == .dark` |
| itermcolors-003 | appearance-inferred | Test `infersLight`: foreground black, background white, no `appearance` | `appearance == .light` |
| itermcolors-004 | appearance-explicit-wins | Test `explicitAppearance`: white on black, `appearance: .light` | `appearance == .light` |
| itermcolors-005 | foreground-equals-background-rejected | Test `rejectsForegroundEqualsBackground`: foreground and background both (0,0,0) | throws `ITermColorsParseError.foregroundMatchesBackground` |
| itermcolors-006 | cursor-fallback, selection-fallback | Test `fallbacks`: white on black, no `Cursor Color`, no `Selection Color` | `cursor == foreground`; `selection == background.blended(withFraction: 0.25, of: foreground)` |
| itermcolors-007 | top-level-must-be-dictionary | Test `notADictionary`: plist root is the array `[1, 2, 3]` | throws `ITermColorsParseError.notADictionary` |
| itermcolors-008 | foreground-required | Test `missingColor`: no `Foreground Color` key | throws `ITermColorsParseError.missingColor("Foreground Color")` |
| itermcolors-009 | component-required | Test `missingComponent`: `Foreground Color` has Green and Blue but no `Red Component` | throws `missingComponent(colorKey: "Foreground Color", component: "Red Component")` |
| itermcolors-010 | alpha-default-opaque | Source: base fixture where `Foreground Color` is `{Red Component: 1.0, Green Component: 1.0, Blue Component: 1.0}` with no `Alpha Component` | decoded color has `alpha == 1.0` and no error |
| itermcolors-011 | channel-clamping | Source: base fixture where `Foreground Color` is `{Red Component: 1.2, Green Component: -0.1, Blue Component: 0.5}`, background black | foreground is `RGBAColor(1.0, 0.0, 0.5, 1.0)` |
| itermcolors-012 | ansi-required | Source: base fixture with white foreground, black background, `Ansi 0` to `Ansi 6` and `Ansi 8` to `Ansi 15` present, `Ansi 7 Color` absent | throws `missingColor("Ansi 7 Color")` |
| itermcolors-013 | degenerate-check-before-ansi | Source: plist with only `Foreground Color` and `Background Color`, both `{Red Component: 0, Green Component: 0, Blue Component: 0}` | throws `foregroundMatchesBackground`, not `missingColor` |
| itermcolors-014 | url-overload-default-name | Source: write the base fixture's XML bytes to a temporary file named `Dracula.itermcolors`, then call `parse(contentsOf:)` with no `name` | `name == "Dracula"` |
| itermcolors-015 | id-default-fresh-uuid | Source: two calls to `parse(data:name:)` with the base fixture's bytes and no `id` | the two themes have different `id` values, each a valid UUID string |
| itermcolors-016 | foundation-errors-propagate | Source: `parse(data:)` on the UTF-8 bytes of `not a plist` | throws a Foundation error from `PropertyListSerialization`, not an `ITermColorsParseError` |
| itermcolors-017 | cursor-fallback | Source: base fixture where `Cursor Color` is `{Red Component: 0.5, Green Component: 0.5}` | no error; `cursor == foreground` |
| itermcolors-018 | parse-data-accepts-xml-and-binary | Source: the base fixture serialized with `PropertyListSerialization` format `.binary` | Parses; the theme equals the one parsed from the `.xml` serialization of the same dictionary |
| itermcolors-019 | selection-fallback | Source: base fixture where `Selection Color` is `{Red Component: 0.5}` (malformed) | no error; `selection == background.blended(withFraction: 0.25, of: foreground)` |
| itermcolors-020 | alpha-default-opaque, component-type-strict | Source: base fixture where `Foreground Color` has `Alpha Component` set to the string `"x"`; separately, `Red Component` set to the string `"x"` | alpha string: no error, foreground alpha `1.0`. Red string: throws `missingComponent(colorKey: "Foreground Color", component: "Red Component")` |
| itermcolors-021 | luminance-boundary-light, appearance-ignores-alpha, foreground-alpha-distinct | Source: three runs with no `appearance`. (a) background grey with relative luminance exactly 0.5 (each channel about 0.7354, adjusted until `isDark` is false), foreground white. (b) background black with `Alpha Component` 0.1, foreground white. (c) foreground and background both black, foreground `Alpha Component` 0.5 | (a) `.light`. (b) `.dark`, same as the opaque black background. (c) no error; foreground not equal to background |
## Edge Cases

- **Empty data** (MUST): zero-length `Data` fails in `PropertyListSerialization` and the Foundation error propagates.
- **Malformed or non-plist bytes** (MUST): the Foundation parse error propagates; it is not an `ITermColorsParseError`.
- **Non-dictionary root**: an array, string or number root throws `notADictionary` (see `top-level-must-be-dictionary`).
- **Required key present but not a dictionary** (MUST): a value of the wrong type under a color key is treated as absent and throws `missingColor` with that key.
- **Component of the wrong type**: see `component-type-strict`. A plist `integer` (for example `1`) bridges to `Double` and is accepted.
- **Out-of-range components**: see `channel-clamping`.
- **Boundary luminance**: see `luminance-boundary-light`.
- **Translucent background**: see `appearance-ignores-alpha`.
- **Foreground differs from background only by alpha**: see `foreground-alpha-distinct`.
- **Malformed optional color**: see `cursor-fallback` and `selection-fallback`. The malformed value is discarded without a signal.
- **Partial files** (MUST): a file with cursor and selection omitted still parses.
- **Extra or unknown keys**: see `extra-keys-ignored`.
- **Unreadable file in the URL overload** (MUST): the error from `Data(contentsOf:)` propagates.
- **Concurrent access**: the parser holds no shared mutable state, so concurrent calls cannot interfere.
- **Cancellation and timeout**: not applicable; the parser is synchronous, has no timeout and no cancellation point.
- **Offline or disconnected state**: not applicable; the URL overload reads a file URL and the parser makes no network request of its own.
- **Large input**: nothing in the source bounds the input size; the whole file is read into memory.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data` | `Data` | required | Raw `.itermcolors` bytes (XML or binary plist), data overload only |
| `url` (`contentsOf`) | `URL` | required | Location of the `.itermcolors` file, URL overload only |
| `name` | `String` (data overload) / `String?` (URL overload) | required / `nil` | Theme display name; the URL overload falls back to the file's base name |
| `id` | `String` | `UUID().uuidString` | Stable theme identifier |
| `appearance` | `ThemeAppearance?` | `nil` | `.dark`, `.light` or `.auto`; `nil` infers from background luminance |

The number of ANSI colors required is `ColorTheme.ansiColorCount` (16), a compile-time constant of `ColorTheme` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.color-theme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6)) that callers cannot set. The parser reads no environment variables and no settings keys. The selection fallback fraction (0.25) and the luminance threshold (0.5, in `RGBAColor.isDark`) are constants in the source.

## Deep Linking

Not applicable: the parser has no URL scheme or navigation surface; its `URL` parameter is a file location.

## Localization

Not applicable: `ITermColorsParseError` carries no user-facing strings, only case names and the offending color key and component name, which are the plist keys themselves. The parser does not localize or format any message.

## Accessibility Options

Not applicable: the parser has no visual or motion output and does not read Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the source reads no feature flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the parser handles color values only, stores nothing and sends nothing; the URL overload reads a file the caller names.

## Logging

Not applicable: the source makes no log calls; failures are surfaced by throwing.

## Platform Notes

- **SwiftUI**: The source platform is Swift. The parser uses `PropertyListSerialization`, `Data`, `URL` and `UUID` from Foundation and has no SwiftUI types; a view binds to the returned `ColorTheme` through `ThemeStore`.
- **Compose**: Android has no built-in plist reader. Parse the XML with `XmlPullParser` or a plist library such as dd-plist; binary plists need a separate decoder. Model errors as a sealed class, hold colors as floats in 0 to 1, and clamp explicitly because `Color(red, green, blue, alpha)` rejects out-of-range floats.
- **React/Web**: Use `DOMParser` on the XML plist and walk the `dict`, `key` and `real` nodes, or a plist package for Node and the browser; binary plists need an extra decoder. Throw typed `Error` subclasses or return a discriminated-union result. Compare colors by all four channels, clamp with `Math.min` and `Math.max`, and read the file with `File.text()` or `fetch` in place of `Data(contentsOf:)`.
- **AppKit / UIKit**: The parser is identical on macOS and iOS because it is Foundation-only. The `NSColor` and `UIColor` bridge lives in the UI layer, as the `RGBAColor` doc comment says. iTerm2 files declare a `Color Space` entry (for example `sRGB` or `Calibrated`), which this parser ignores and does not convert.
- **WinUI 3**: Port as a `static class ITermColorsParser` with `Parse(byte[] data, string name, string? id = null, ThemeAppearance? appearance = null)` and a file overload taking a `StorageFile` or path. Decode the XML plist with `System.Xml.Linq.XDocument`, walking `dict` children as alternating `key` and `real` elements; .NET has no binary plist support, so ports MUST add a binary plist library (`parse-data-accepts-xml-and-binary` requires both encodings, as Foundation provides). Read the file with `await FileIO.ReadBufferAsync(StorageFile)` from `Windows.Storage` or `File.ReadAllBytes`, making the file overload `async Task<ColorTheme>`. Replace the Swift `throws` enum with an exception hierarchy or a result type carrying `ColorKey` and `Component` fields. Represent `RGBAColor` as a `readonly record struct` with `double` channels and a clamping constructor, which gives the value equality the foreground/background check relies on. Convert to `Windows.UI.Color` (byte channels) or `SolidColorBrush` only in the UI layer; `INotifyPropertyChanged` is unnecessary because the parser holds no state. Use `Guid.NewGuid().ToString().ToUpperInvariant()` for the default id to match `UUID().uuidString`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ITermColorsParser.swift` | confirmed (1.0.3) |

## Design Decisions

**Decision**: Foreground, background and all 16 ANSI colors are required and fail fast; cursor and selection fall back to palette-derived values.
**Rationale**: Cursor and selection each have a safe palette-derived substitute (the foreground, and a background-to-foreground blend), so a file without them still yields a usable theme. The foreground, background and ANSI colors have no substitute, and the palette is what makes a theme usable. The doc comment on `parse` describes cursor and selection as "common but not universal"; that is the source's claim and no external sample is cited here.
**Approved**: pending

**Decision**: A theme whose foreground equals its background is rejected with `foregroundMatchesBackground`.
**Rationale**: Text drawn in the background color is invisible, so such a theme is rejected rather than imported into an unusable state. This follows from the colors being identical; the doc comment on `ITermColorsParseError.foregroundMatchesBackground` makes the same point.
**Approved**: pending

**Decision**: Appearance is inferred from the background's relative luminance unless the caller supplies one.
**Rationale**: `.itermcolors` carries no dark/light flag; the source infers it with `isDark` and lets the caller override, including with `.auto`.
**Approved**: pending

**Decision**: The `try?` around cursor and selection discards every error for those two keys, including a present-but-malformed dictionary.
**Rationale**: The fallback is the source's deliberate way to keep partial files importable; it trades a signal about malformed optional colors for leniency. Ports should match it.
**Approved**: pending

**Decision**: Alpha defaults to 1.0 when absent or not a `Double`.
**Rationale**: A color with no alpha is conventionally opaque, so an absent alpha is treated as `1.0`; the comment on the alpha read in `ITermColorsParser.swift` says alpha is "frequently omitted". A present but non-numeric alpha also becomes `1.0`, unlike the other components, which throw.
**Approved**: pending

**Decision**: Plist decode errors and file read errors are not wrapped in `ITermColorsParseError`.
**Rationale**: The doc comment promises `ITermColorsParseError` for malformed structure and missing colors; Foundation's errors for undecodable bytes and unreadable files pass through unchanged, so callers must catch both kinds.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

The parser does one job, turning plist bytes into a `ColorTheme`, and leaves storage, the imported flag and platform color bridges to `ThemeStore` and the UI layer, so separation of concerns passes. Every structural failure throws a typed `ITermColorsParseError` case or a propagated Foundation error; the only discarded errors are the documented cursor and selection fallbacks, so explicit error handling passes. Unit-test coverage passes: `ITermColorsParserTests` (`packages/apple/AgenticDeveloperHubSDK/SDK/Tests/AgenticDeveloperHubSDKTests/Theme/ITermColorsParserTests.swift`) covers all 21 vectors, including the URL overload and its default name, the missing ANSI color, alpha defaulting, clamping, binary plists and propagated Foundation errors.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (ITermColorsParserTests.swift, 21 of 21 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Spelled out the blend and luminance formulas, named three boundary requirements, removed private helper names and duplicate edge-case MUSTs, gave vectors 010 to 021 concrete fixtures and labelled them untested, and set the binary-plist and alpha rules. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
