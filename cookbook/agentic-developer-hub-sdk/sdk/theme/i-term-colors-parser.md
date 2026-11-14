---
id: 231a7e9a-8c03-44b3-afaf-b71755e05c1d
title: "ITermColorsParser"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
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
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# ITermColorsParser

## Overview

`ITermColorsParser` is a stateless, caseless `enum` that turns the bytes of an iTerm2 `.itermcolors` file into a `ColorTheme`. An `.itermcolors` file is a property list (XML or binary) whose top-level dictionary maps color keys (`Ansi 0 Color` through `Ansi 15 Color`, `Foreground Color`, `Background Color`, `Cursor Color`, `Selection Color`) to dictionaries of `Red Component`, `Green Component`, `Blue Component` and `Alpha Component` reals in 0 to 1. The parser uses Foundation's `PropertyListSerialization` and has no third-party dependency.

Use it to import a terminal color scheme as an app theme. The parser is strict about the foreground, background and 16 ANSI colors, and lenient about cursor, selection and alpha. It does no I/O of its own except the URL overload, which reads the file with `Data(contentsOf:)`.

## Behavioral Requirements

Public surface: `ITermColorsParser.parse(data:name:id:appearance:)`, `ITermColorsParser.parse(contentsOf:name:id:appearance:)`, and the error enum `ITermColorsParseError` (`Error`, `Equatable`) with cases `notADictionary`, `missingColor(String)`, `missingComponent(colorKey:component:)` and `foregroundMatchesBackground`.

- **parse-data-returns-theme**: `parse(data:name:id:appearance:)` MUST return a `ColorTheme` built from the plist bytes, with `name` set to the supplied name.
- **parse-data-accepts-xml-and-binary**: `parse(data:)` MUST accept both XML and binary property-list encodings, since it delegates decoding to `PropertyListSerialization` with `format: nil`.
- **id-default-fresh-uuid**: When `id` is not supplied, the theme's `id` MUST be a fresh `UUID().uuidString`; when supplied, the theme's `id` MUST equal the supplied string.
- **not-built-in**: The returned theme MUST have `isBuiltIn` equal to `false`.
- **imported-flag-untouched**: The parser MUST NOT mark the theme imported; `isImported` keeps the `ColorTheme` initializer default. The caller (`ThemeStore.importITermColors`) sets it after parsing.
- **top-level-must-be-dictionary**: The parser MUST throw `ITermColorsParseError.notADictionary` when the decoded plist root is not a `[String: Any]` dictionary.
- **foreground-required**: The parser MUST throw `missingColor("Foreground Color")` when the top-level dictionary has no dictionary value under `Foreground Color`.
- **background-required**: The parser MUST throw `missingColor("Background Color")` when the top-level dictionary has no dictionary value under `Background Color`.
- **ansi-required**: The parser MUST read `Ansi 0 Color` through `Ansi 15 Color` (`ColorTheme.ansiColorCount`, 16) in index order and MUST throw `missingColor("Ansi N Color")` for the first absent index.
- **ansi-order-preserved**: The returned `ansi` array MUST hold exactly 16 colors, where element N is the color decoded from `Ansi N Color`.
- **component-required**: Within any required color dictionary, the parser MUST throw `missingComponent(colorKey:component:)` naming the color key and the first missing component among `Red Component`, `Green Component`, `Blue Component`, checked in that order.
- **component-type-strict**: A component present but not castable to `Double` (a plist `integer` is castable and is accepted) MUST be treated as missing and MUST throw `missingComponent`.
- **alpha-default-opaque**: When `Alpha Component` is absent or not a `Double`, the parser MUST use alpha `1.0`; a missing alpha MUST NOT raise an error.
- **extra-keys-ignored**: Keys the parser does not read (for example `Color Space`, `Bold Color`, `Link Color`, `Cursor Text Color`) MUST be ignored.
- **channel-clamping**: Every decoded channel MUST be clamped to 0 to 1, because each color is built through the `RGBAColor` initializer, which clamps its components.
- **foreground-equals-background-rejected**: The parser MUST throw `foregroundMatchesBackground` when the decoded foreground and background `RGBAColor` values are equal (all four channels, after clamping).
- **degenerate-check-before-ansi**: The foreground/background equality check MUST run after both colors decode and before any ANSI color is read, so an equal pair is reported even when the ANSI colors are missing.
- **cursor-fallback**: When `Cursor Color` is absent or fails to decode for any reason, the parser MUST use the foreground color as the cursor color and MUST NOT throw.
- **selection-fallback**: When `Selection Color` is absent or fails to decode for any reason, the parser MUST use `background.blended(withFraction: 0.25, of: foreground)` as the selection color and MUST NOT throw.
- **appearance-explicit-wins**: When `appearance` is non-nil, the theme's `appearance` MUST equal it exactly, including `.auto`.
- **appearance-inferred**: When `appearance` is `nil`, the theme's `appearance` MUST be `.dark` if `background.isDark` (relative luminance below 0.5, alpha ignored) and `.light` otherwise.
- **url-overload-reads-file**: `parse(contentsOf:name:id:appearance:)` MUST read the file with `Data(contentsOf:)` and delegate to `parse(data:name:id:appearance:)` with the other arguments unchanged.
- **url-overload-default-name**: When `name` is `nil`, the URL overload MUST use the file's base name, `url.deletingPathExtension().lastPathComponent` (`Dracula.itermcolors` becomes `Dracula`).
- **fail-fast**: The parser MUST stop at the first structural error and MUST NOT return a partial theme.
- **foundation-errors-propagate**: Errors from `PropertyListSerialization` (undecodable bytes) and from `Data(contentsOf:)` (unreadable file) MUST propagate to the caller unchanged and are not wrapped in `ITermColorsParseError`.
- **concurrency**: The parser holds no state; the two `parse` functions and the private `color(in:forKey:)` and `component(_:_:colorKey:)` helpers are static and pure apart from the URL overload's file read, so concurrent calls MAY run in parallel. Nothing in the source serialises or isolates them.
- **side-effects**: The data overload MUST have no side effect; the URL overload's only side effect is reading one file. The parser writes no files, makes no network calls, posts no notifications and logs nothing.

## Appearance

Not applicable — this is a file-format parser, not a visual component.

## States

Not applicable — this is a file-format parser, not a visual component.

## Accessibility

Not applicable — this is a file-format parser, not a visual component.

## Conformance Test Vectors

Vectors derive from `ITermColorsParserTests` (Swift Testing suite `ITermColorsParser`) unless marked "source". The fixture builds a plist with all 16 ANSI colors plus `Foreground Color`, `Background Color`, and optional `Cursor Color` (0.9, 0.9, 0.9) and `Selection Color` (0.2, 0.2, 0.2).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| itermcolors-001 | parse-data-returns-theme, ansi-order-preserved, not-built-in | Test `parsesPalette`: foreground (1,1,1), background (0,0,0), `Ansi 5 Color` (1,0,0.5), rest black; name `Test` | `name == "Test"`; foreground is `RGBAColor(1,1,1,1)`; background `RGBAColor(0,0,0,1)`; `ansi.count == 16`; `ansi[5] == RGBAColor(1,0,0.5,1)`; `isBuiltIn == false` |
| itermcolors-002 | appearance-inferred | Test `infersDark`: foreground white, background black, no `appearance` | `appearance == .dark` |
| itermcolors-003 | appearance-inferred | Test `infersLight`: foreground black, background white, no `appearance` | `appearance == .light` |
| itermcolors-004 | appearance-explicit-wins | Test `explicitAppearance`: white on black, `appearance: .light` | `appearance == .light` |
| itermcolors-005 | foreground-equals-background-rejected | Test `rejectsForegroundEqualsBackground`: foreground and background both (0,0,0) | throws `ITermColorsParseError.foregroundMatchesBackground` |
| itermcolors-006 | cursor-fallback, selection-fallback | Test `fallbacks`: white on black, no `Cursor Color`, no `Selection Color` | `cursor == foreground`; `selection == background.blended(withFraction: 0.25, of: foreground)` |
| itermcolors-007 | top-level-must-be-dictionary | Test `notADictionary`: plist root is the array `[1, 2, 3]` | throws `ITermColorsParseError.notADictionary` |
| itermcolors-008 | foreground-required, fail-fast | Test `missingColor`: no `Foreground Color` key | throws `ITermColorsParseError.missingColor("Foreground Color")` |
| itermcolors-009 | component-required | Test `missingComponent`: `Foreground Color` has Green and Blue but no `Red Component` | throws `missingComponent(colorKey: "Foreground Color", component: "Red Component")` |
| itermcolors-010 | alpha-default-opaque | Source: a color dictionary with Red, Green, Blue and no `Alpha Component` | decoded color has `alpha == 1.0` and no error |
| itermcolors-011 | channel-clamping | Source: `Red Component` 1.2 and `Green Component` -0.1 | decoded channels are 1.0 and 0.0 |
| itermcolors-012 | ansi-required | Source: all required colors present except `Ansi 7 Color` | throws `missingColor("Ansi 7 Color")` |
| itermcolors-013 | degenerate-check-before-ansi | Source: foreground equals background and all ANSI keys absent | throws `foregroundMatchesBackground`, not `missingColor` |
| itermcolors-014 | url-overload-default-name | Source: `parse(contentsOf:)` on `/tmp/Dracula.itermcolors` with no `name` | `name == "Dracula"` |
| itermcolors-015 | id-default-fresh-uuid | Source: two calls to `parse(data:name:)` with the same data and no `id` | the two themes have different `id` values, each a valid UUID string |
| itermcolors-016 | foundation-errors-propagate | Source: `parse(data:)` on the bytes `not a plist` | throws a Foundation error from `PropertyListSerialization`, not an `ITermColorsParseError` |
| itermcolors-017 | cursor-fallback | Source: `Cursor Color` present but missing `Blue Component` | no error; `cursor == foreground` |

## Edge Cases

- **Empty data** (MUST): zero-length `Data` fails in `PropertyListSerialization` and the Foundation error propagates.
- **Malformed or non-plist bytes** (MUST): the Foundation parse error propagates; it is not an `ITermColorsParseError`.
- **Non-dictionary root** (MUST): an array, string or number root throws `notADictionary`.
- **Required key present but not a dictionary** (MUST): a value of the wrong type under a color key is treated as absent and throws `missingColor` with that key.
- **Component of the wrong type** (MUST): a string or other value that does not bridge to `Double` under a component key throws `missingComponent`. A plist `integer` (for example `1`) bridges to `Double` and is accepted.
- **Out-of-range components** (MUST): values below 0 or above 1 clamp to 0 and 1, per the `RGBAColor` initializer's doc comment.
- **Boundary luminance** (MUST): a background with relative luminance exactly 0.5 is `.light`, because `isDark` is a strict less-than.
- **Translucent background** (MUST): alpha does not enter the dark/light inference, because `relativeLuminance` reads only the channels.
- **Foreground differs from background only by alpha** (MUST): the colors compare unequal, so the theme is accepted.
- **Malformed optional color** (MUST): a `Cursor Color` or `Selection Color` that exists but is malformed is treated like an absent one and falls back silently. This is deliberate, per the source comment that cursor and selection are "common but not universal", and the malformed value is discarded without a signal.
- **Partial files** (MUST): a file with cursor and selection omitted still parses.
- **Extra or unknown keys** (MUST): ignored.
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
| `ColorTheme.ansiColorCount` | `Int` | `16` | Number of ANSI colors required, injected from `ColorTheme` |

The parser reads no environment variables and no settings keys. The selection fallback fraction (0.25) and the luminance threshold (0.5, in `RGBAColor.isDark`) are constants in the source.

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

- **SwiftUI**: The source platform is Swift, in `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ITermColorsParser.swift`. It uses `PropertyListSerialization`, `Data`, `URL` and `UUID` from Foundation, and depends on the sibling files `ColorTheme.swift`, `RGBAColor.swift` and `RGBAColor+Theme.swift` (`isDark`, `blended(withFraction:of:)`). It has no SwiftUI types; a view binds to the returned `ColorTheme` through `ThemeStore`.
- **Compose**: Android has no built-in plist reader. Parse the XML with `XmlPullParser` or a plist library such as dd-plist; binary plists need a separate decoder. Model errors as a sealed class, hold colors as floats in 0 to 1, and clamp explicitly because `Color(red, green, blue, alpha)` rejects out-of-range floats.
- **React/Web**: Use `DOMParser` on the XML plist and walk the `dict`, `key` and `real` nodes, or a plist package for Node and the browser; binary plists need an extra decoder. Throw typed `Error` subclasses or return a discriminated-union result. Compare colors by all four channels, clamp with `Math.min` and `Math.max`, and read the file with `File.text()` or `fetch` in place of `Data(contentsOf:)`.
- **AppKit / UIKit**: The parser is identical on macOS and iOS because it is Foundation-only. The `NSColor` and `UIColor` bridge lives in the UI layer, as the `RGBAColor` doc comment says. iTerm2 files declare a `Color Space` entry (for example `sRGB` or `Calibrated`), which this parser ignores and does not convert.
- **WinUI 3**: Port as a `static class ITermColorsParser` with `Parse(byte[] data, string name, string? id = null, ThemeAppearance? appearance = null)` and a file overload taking a `StorageFile` or path. Decode the XML plist with `System.Xml.Linq.XDocument`, walking `dict` children as alternating `key` and `real` elements; .NET has no binary plist support, so reject the `bplist` case or add a library, since Foundation accepts it. Read the file with `await FileIO.ReadBufferAsync(StorageFile)` from `Windows.Storage` or `File.ReadAllBytes`, making the file overload `async Task<ColorTheme>`. Replace the Swift `throws` enum with an exception hierarchy or a result type carrying `ColorKey` and `Component` fields. Represent `RGBAColor` as a `readonly record struct` with `double` channels and a clamping constructor, which gives the value equality the foreground/background check relies on. Convert to `Windows.UI.Color` (byte channels) or `SolidColorBrush` only in the UI layer; `INotifyPropertyChanged` is unnecessary because the parser holds no state. Use `Guid.NewGuid().ToString().ToUpperInvariant()` for the default id to match `UUID().uuidString`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/ITermColorsParser.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Foreground, background and all 16 ANSI colors are required and fail fast; cursor and selection fall back to palette-derived values.
**Rationale**: The source comment says cursor and selection are "common but not universal", so partial files still yield a usable theme, while the palette itself is what makes a theme usable.
**Approved**: pending

**Decision**: A theme whose foreground equals its background is rejected with `foregroundMatchesBackground`.
**Rationale**: The doc comment on the error says such a theme renders all text invisible, so it is rejected rather than imported into an unusable state.
**Approved**: pending

**Decision**: Appearance is inferred from the background's relative luminance unless the caller supplies one.
**Rationale**: `.itermcolors` carries no dark/light flag; the source infers it with `isDark` and lets the caller override, including with `.auto`.
**Approved**: pending

**Decision**: The `try?` around cursor and selection discards every error for those two keys, including a present-but-malformed dictionary.
**Rationale**: The fallback is the source's deliberate way to keep partial files importable; it trades a signal about malformed optional colors for leniency. Ports should match it.
**Approved**: pending

**Decision**: Alpha defaults to 1.0 when absent or not a `Double`.
**Rationale**: The source comment says alpha is "frequently omitted", so a missing alpha is treated as opaque.
**Approved**: pending

**Decision**: Plist decode errors and file read errors are not wrapped in `ITermColorsParseError`.
**Rationale**: The doc comment promises `ITermColorsParseError` for malformed structure and missing colors; Foundation's errors for undecodable bytes and unreadable files pass through unchanged, so callers must catch both kinds.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

The parser does one job, turning plist bytes into a `ColorTheme`, and leaves storage, the imported flag and platform color bridges to `ThemeStore` and the UI layer, so separation of concerns passes. Every structural failure throws a typed `ITermColorsParseError` case or a propagated Foundation error; the only discarded errors are the documented cursor and selection fallbacks, so explicit error handling passes. Unit-test coverage is partial: `ITermColorsParserTests` covers the palette, both appearance paths, the equal-colors rejection, the fallbacks, and three error cases, but has no test for the URL overload and its default name, the missing ANSI color, alpha defaulting, clamping, binary plists or propagated Foundation errors.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
