
The source has no test file of its own. Vectors derive from the source's documented behavior. Neighboring tests use the type only indirectly: `RGBAColorThemeTests` builds in-range colors to test compositing, `PortedThemeTests` and `SemanticPaletteTests` parse lowercase eight-digit strings such as `RGBAColor(hexString: "#00ff41ff")!`, `SemanticPaletteTests` reads `hexString` for uniqueness, and `ITermColorsParserTests` compares components built with the component initializer.

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
| rgbacolor-010 | hex-sign-leniency | `"+FFFFFFF"` (source behavior only; a port MAY reject it) | non-nil; red is 0x0F/255 |
| rgbacolor-011 | hex-format, hex-rounding | `RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1).hexString` | `"#336699FF"` |
| rgbacolor-012 | hex-format | `RGBAColor.clear.hexString` | `"#00000000"` |
| rgbacolor-013 | clamp-range, hex-format | `RGBAColor(red: 9, green: -9, blue: 0, alpha: 1).hexString` (the initializer has already clamped; `hex-clamp-again` is defensive and has no vector) | `"#FF0000FF"` |
| rgbacolor-014 | encode-single-string | `JSONEncoder` on `RGBAColor.white` wrapped in an array | `["#FFFFFFFF"]` |
| rgbacolor-015 | decode-single-string, roundtrip-byte-exact | decode `["#336699FF"]` then read `hexString` | `"#336699FF"` |
| rgbacolor-016 | decode-error | decode `["red"]` as `RGBAColor` | throws `DecodingError.dataCorrupted` with the message `Expected #RRGGBBAA hex color string.` |
| rgbacolor-017 | decode-error | decode `[12]` as `RGBAColor` | throws a decoding error (type mismatch) |
| rgbacolor-018 | constants | `black`, `white`, `clear` | (0,0,0,1), (1,1,1,1), (0,0,0,0) |
| rgbacolor-019 | value-semantics | two colors built from identical components | `==` is true |
| rgbacolor-020 | hex-no-whitespace | `" #FF000080"` and `"FF00008 "` | nil each |
| rgbacolor-021 | hex-no-shorthand, hex-length | `"#FFFF"` (4 digits) and `"#FF00008"` (7 digits) | nil each |
| rgbacolor-022 | hex-sign-leniency | `"-0000000"` (source behavior only; a port MAY reject it) | non-nil; red, green, blue and alpha all 0 |
| rgbacolor-023 | hex-rounding, roundtrip-byte-exact | `RGBAColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).hexString`, then `RGBAColor(hexString:)` on the result | `"#808080FF"`; the decoded red is 128/255 and is not equal to 0.5 |
