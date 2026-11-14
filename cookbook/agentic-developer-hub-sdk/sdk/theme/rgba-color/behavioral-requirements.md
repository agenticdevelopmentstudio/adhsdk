
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

