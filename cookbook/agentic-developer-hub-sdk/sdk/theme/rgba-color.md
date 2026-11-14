---
id: ad5bae6b-0172-4cd4-a4b7-297eb58eb28d
title: RGBAColor
type: ingredient
version: 1.0.0
status: review
language: en
created: '2026-11-14'
modified: '2026-11-14'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'Platform-neutral RGBA color value with components clamped to 0 through 1
  that encodes as an uppercase #RRGGBBAA hex string.'
platforms:
- swift
- macos
- ios
tags:
- theme
- color
- codable
- logic
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# RGBAColor

## Overview

`RGBAColor` is a platform-neutral color value with four `Double` components (`red`, `green`, `blue`, `alpha`) held in the range 0 to 1. It exists so theme and settings data can be stored without a dependency on `NSColor` or `UIColor`: it encodes as the string `"#RRGGBBAA"`, which round-trips through `UserDefaults`. The source's own comment says UI layers add the platform-color bridge. It is a pure value type with no I/O and no state.

The source file also defines three constants (`black`, `white`, `clear`). Luminance, blending and compositing helpers live in a separate extension file (`RGBAColor+Theme.swift`) and belong to the theme layer, not to this contract.

## Behavioral Requirements

Data shape

- **fields**: `RGBAColor` MUST expose four read-only `Double` properties named `red`, `green`, `blue` and `alpha`.
- **value-semantics**: `RGBAColor` MUST be a value type that is `Equatable`, `Codable` and `Sendable`. Equality is the synthesized memberwise comparison of the four components.

Component initializer

- **clamp-range**: The component initializer `init(red:green:blue:alpha:)` MUST clamp each component into the range 0 to 1 inclusive: values below 0 become 0 and values above 1 become 1.
- **clamp-nan**: The component initializer MUST store 0 for a NaN component, so a stored channel is never non-finite. The source comment names "a NaN from color math" as a case this protects against.
- **clamp-infinity**: The component initializer MUST store 1 for positive infinity and 0 for negative infinity.
- **clamp-no-error**: The component initializer MUST NOT throw, trap or return nil for any `Double` input.
- **clamp-reason**: The clamp exists because a malformed source, such as an imported `.itermcolors` with an out-of-gamut or rounding-artifact value, must never store an out-of-range channel that later corrupts rendering or traps on conversion.

Hex parsing

- **hex-init-failable**: `init?(hexString:)` MUST return nil on any parse failure and MUST NOT throw.
- **hex-length**: `init?(hexString:)` MUST return nil unless the string, after one optional leading `#` is removed, is exactly 8 characters long.
- **hex-optional-hash**: `init?(hexString:)` MUST accept the string with or without a single leading `#`. Only one `#` is removed, so `"##RRGGBBAA"` fails the length check.
- **hex-case-insensitive**: `init?(hexString:)` MUST accept upper-case, lower-case and mixed-case hex digits.
- **hex-non-hex**: `init?(hexString:)` MUST return nil when the 8 characters are not a valid base-16 `UInt32`.
- **hex-channel-order**: `init?(hexString:)` MUST read the 32-bit value as red in the top byte, then green, then blue, then alpha in the low byte.
- **hex-normalize**: `init?(hexString:)` MUST divide each byte by 255 to produce a component in 0 to 1.
- **hex-sign-leniency**: The 8-character body is parsed by `UInt32(_:radix:)`, so a leading `+` counts toward the 8 characters and is accepted (`"+FFFFFFF"` parses as 0x0FFFFFFF), and `"-0000000"` parses as 0. The doc comment documents `"#RRGGBBAA"` only; this leniency is the standard-library parse and is not rejected by the source. A port that wants identical acceptance sets MUST accept these strings.
- **hex-no-shorthand**: `init?(hexString:)` MUST return nil for 3-, 4-, 6- and 7-digit forms; only the 8-digit `RRGGBBAA` form parses.
- **hex-no-whitespace**: `init?(hexString:)` MUST return nil for a string with leading or trailing whitespace, because the 8-character count and the integer parse both reject it.

Hex serialization

- **hex-format**: The `hexString` property MUST return `"#"` followed by eight upper-case hexadecimal digits, always 9 characters long, in the order red, green, blue, alpha, each zero-padded to two digits.
- **hex-rounding**: The `hexString` property MUST convert each component to a byte as the component, clamped to 0 to 1, times 255, rounded to the nearest integer (halves away from zero, Swift's `rounded()`).
- **hex-clamp-again**: The `hexString` property MUST clamp each component again before conversion, so it never emits a byte outside 00 to FF even if the fields were populated without going through the component initializer.
- **hex-always-alpha**: The `hexString` property MUST include alpha; there is no 6-digit output form in this type.

Codable

- **encode-single-string**: Encoding MUST write a single string value (a single-value container) equal to `hexString`, not a keyed object.
- **decode-single-string**: Decoding MUST read a single string value and construct the color with `init?(hexString:)`.
- **decode-error**: Decoding MUST throw `DecodingError.dataCorruptedError` with the debug description `"Expected #RRGGBBAA hex color string."` when the string does not parse. A non-string value fails with the decoder's own type-mismatch error before the parse.
- **roundtrip-byte-exact**: For any color whose components are exact multiples of 1/255, encode then decode MUST return an equal value. For other colors the round trip is quantized to 8 bits per channel.

Constants

- **constants**: The type MUST provide `black` (0, 0, 0, 1), `white` (1, 1, 1, 1) and `clear` (0, 0, 0, 0) as static constants.

Concurrency and side effects

- **sendable**: `RGBAColor` MUST be `Sendable`; every member is an immutable value, so any thread MAY use it without synchronization.
- **no-side-effects**: Every operation in this contract MUST NOT perform I/O, logging, notification or persistence. Persistence is by the caller, through `Codable`.

## Appearance

Not applicable — this is a color value type, not a visual component.

## States

Not applicable — this is an immutable value type, not a visual component. All four fields are `let` constants, so an instance never changes after it is built.

## Accessibility

Not applicable — this is a color value type, not a visual component. The type carries no contrast or labeling logic; the WCAG luminance helper is in `RGBAColor+Theme.swift`.

## Conformance Test Vectors

The source has no test file of its own. Vectors derive from the source's documented behavior; the neighboring tests that exercise the type are `RGBAColorThemeTests` (construction with in-range components) and `PortedThemeTests` and `SemanticPaletteTests` (`RGBAColor(hexString: "#00ff41ff")!` and similar lowercase eight-digit strings parse and compare equal).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| rgbacolor-001 | clamp-range | `RGBAColor(red: -0.5, green: 1.5, blue: 0.25, alpha: 2)` | red 0, green 1, blue 0.25, alpha 1 |
| rgbacolor-002 | clamp-nan, clamp-no-error | `RGBAColor(red: .nan, green: 0.5, blue: 0.5, alpha: 1)` | red is 0; no trap |
| rgbacolor-003 | clamp-infinity | `RGBAColor(red: .infinity, green: -.infinity, blue: 0, alpha: 1)` | red 1, green 0 |
| rgbacolor-004 | hex-channel-order, hex-normalize | `RGBAColor(hexString: "#FF000080")` | red 1, green 0, blue 0, alpha 128/255 |
| rgbacolor-005 | hex-optional-hash | `RGBAColor(hexString: "00ff41ff")` and `RGBAColor(hexString: "#00ff41ff")` | both non-nil and equal |
| rgbacolor-006 | hex-case-insensitive | `"#aBcDeF12"` and `"#ABCDEF12"` | equal values |
| rgbacolor-007 | hex-length, hex-no-shorthand | `"#FFF"`, `"#FF0000"`, `""`, `"#"` | nil each |
| rgbacolor-008 | hex-length | `"##FF000080"` | nil |
| rgbacolor-009 | hex-non-hex | `"#GG000080"` | nil |
| rgbacolor-010 | hex-sign-leniency | `"+FFFFFFF"` | non-nil; red is 0x0F/255 |
| rgbacolor-011 | hex-format, hex-rounding | `RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1).hexString` | `"#336699FF"` |
| rgbacolor-012 | hex-format | `RGBAColor.clear.hexString` | `"#00000000"` |
| rgbacolor-013 | hex-clamp-again | `RGBAColor(red: 9, green: -9, blue: 0, alpha: 1).hexString` | `"#FF0000FF"` |
| rgbacolor-014 | encode-single-string | `JSONEncoder` on `RGBAColor.white` wrapped in an array | `["#FFFFFFFF"]` |
| rgbacolor-015 | decode-single-string, roundtrip-byte-exact | decode `["#336699FF"]` then read `hexString` | `"#336699FF"` |
| rgbacolor-016 | decode-error | decode `["red"]` as `RGBAColor` | throws `DecodingError.dataCorrupted` with the message `Expected #RRGGBBAA hex color string.` |
| rgbacolor-017 | decode-error | decode `[12]` as `RGBAColor` | throws a decoding error (type mismatch) |
| rgbacolor-018 | constants | `black`, `white`, `clear` | (0,0,0,1), (1,1,1,1), (0,0,0,0) |
| rgbacolor-019 | value-semantics | two colors built from identical components | `==` is true |
| rgbacolor-020 | hex-no-whitespace | `" #FF000080"` and `"FF00008 "` | nil each |

## Edge Cases

- **Empty or missing input**: `init?(hexString:)` returns nil for `""` and for `"#"` (length is not 8). MUST.
- **Boundary values**: components exactly 0 and 1 are stored unchanged; a hex byte `FF` becomes exactly 1 and `00` exactly 0. MUST.
- **Non-finite components**: NaN stores 0, positive infinity stores 1, negative infinity stores 0, because the clamp is `min(1, max(0, x))`. MUST.
- **Malformed hex**: wrong length, non-hex characters, repeated `#`, shorthand forms and surrounding whitespace return nil and never throw from the failable initializer. MUST.
- **Sign characters**: `"+FFFFFFF"` and `"-0000000"` parse because the standard-library integer parse accepts a sign; see `hex-sign-leniency`. MUST (to match the source).
- **Precision loss**: a color that is not a multiple of 1/255 changes after a hex round trip, for example 0.5 encodes as `80` (127.5 rounds to 128) and decodes as 128/255. Equality after a round trip is therefore not guaranteed for arbitrary `Double` components. This is a deliberate 8-bit projection. SHOULD be treated as expected by callers.
- **Decode failure**: an unparseable string throws `DecodingError.dataCorruptedError` and the caller decides whether to fall back; the type does not substitute a default. MUST.
- **Concurrent access**: not applicable beyond `Sendable`; all fields are immutable, so concurrent reads cannot race.
- **Offline or disconnected state**: not applicable; the type performs no network or file access.
- **Cancellation and timeouts**: not applicable; every operation is synchronous and bounded.

## Configuration

Not applicable: the type takes no parameters, environment variables, settings keys or injected dependencies beyond its four initializer arguments or the hex string. The hex format is fixed (`#RRGGBBAA`, upper-case on output).

## Deep Linking

Not applicable: `RGBAColor` is a value type with no screens or URL routes.

## Localization

The one user-visible-adjacent string is the decoding error's debug description, a hardcoded English literal.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal in source) | Expected #RRGGBBAA hex color string. | `debugDescription` of the `DecodingError` thrown on an unparseable hex string; a developer-facing diagnostic, not shown through a localization table |

## Accessibility Options

Not applicable: the type holds a color and does not respond to Reduce Motion, Increase Contrast or Differentiate Without Color; it has no rendering code.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the type holds a color value only. It collects and transmits nothing, and the only persistence is whatever the caller does with the encoded string (the source comment names `UserDefaults`).

## Logging

Not applicable: the source makes no log calls; parse failure is reported as nil or a thrown `DecodingError`.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/RGBAColor.swift`. It imports only `Foundation`, so it compiles for macOS and iOS. A SwiftUI view builds `Color(.sRGB, red:green:blue:opacity:)` from the four components; that bridge lives in the UI layers, not in this file.
- **Compose**: Use `androidx.compose.ui.graphics.Color(red, green, blue, alpha)` as the bridge, which takes floats in 0 to 1. Compose's `Color` already holds clamped floats, so keep a thin wrapper if the clamp and the `#RRGGBBAA` string must match; note that Android's `Color.parseColor` expects `#AARRGGBB` (alpha first), which differs from this type's alpha-last order.
- **React/Web**: Port as an immutable TypeScript class or readonly object with a `clamp` helper (`Math.min(1, Math.max(0, x))` returns NaN for NaN, so test `Number.isNaN` explicitly to store 0 as the source does). CSS 8-digit hex is also `#RRGGBBAA`, so the string can be used directly in `color` values; `JSON.stringify` writes it as a plain string if `toJSON` returns the hex.
- **AppKit / UIKit**: The macOS bridge is in `RGBAColor+NSColor.swift` under the macOS UI layer; build `NSColor(srgbRed:green:blue:alpha:)` or `UIColor(red:green:blue:alpha:)` from the components. Convert through `RGBAColor` first so out-of-range values are clamped before they reach the platform color.
- **WinUI 3**: Make `RGBAColor` an immutable `readonly record struct` with four `double` properties and a static factory that clamps with `Math.Clamp` (note `Math.Clamp` returns NaN for NaN, so check `double.IsNaN` first and store 0). Parse hex with `uint.TryParse(span, NumberStyles.AllowHexSpecifier, CultureInfo.InvariantCulture, out var value)` after stripping one leading `#`; this rejects a `+` or `-` sign, so add it deliberately only if the source's leniency must be matched. Serialize with a `System.Text.Json.Serialization.JsonConverter<RGBAColor>` that reads and writes a single string, formatting each byte with `X2` after `Math.Round(x * 255, MidpointRounding.AwayFromZero)` to match Swift's `rounded()`. Bridge to the UI with `Windows.UI.Color.FromArgb(a, r, g, b)` (alpha first) for a `SolidColorBrush`; the struct is value-typed and thread-safe without `INotifyPropertyChanged`.

## Design Decisions

**Decision**: Components are clamped in the public initializer, and `hexString` clamps again.
**Rationale**: The source comment states a malformed import or NaN from color math must never store an out-of-range or non-finite channel; the second clamp keeps conversion to a byte from trapping.
**Approved**: pending

**Decision**: The type encodes as one `"#RRGGBBAA"` string rather than a keyed object.
**Rationale**: The source comment says this lets settings round-trip cleanly through `UserDefaults`. The cost is 8-bit quantization.
**Approved**: pending

**Decision**: The hex parser requires all eight digits and accepts the leading `#` optionally.
**Rationale**: Alpha is always present, which keeps the stored format unambiguous; the type offers no 6-digit input form. The integer parse also admits a leading sign, which the doc comment does not mention and the source does not reject.
**Approved**: pending

**Decision**: Parse failure is a nil return from the failable initializer; the `Decodable` path converts it to a thrown `DecodingError`.
**Rationale**: Callers parsing user text can branch on nil, while decoders get the standard error type. The decoded error message is English and not localized.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

Separation of concerns passes because the file holds only the value, its hex form and its `Codable` conformance, and leaves platform-color bridges and luminance math to other files. Unit-test coverage is partial: the source has no test file of its own, and only indirect use through the theme tests exercises `init?(hexString:)`; the clamp, the encode and decode paths and the error case have no direct assertions. Explicit error handling passes because failure is a nil return or a thrown `DecodingError`, never silent. Data integrity passes because both the initializer and `hexString` clamp. No-hardcoded-strings is partial because the decode error's debug description is an English literal, although it is a developer diagnostic.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | | | Initial creation |
