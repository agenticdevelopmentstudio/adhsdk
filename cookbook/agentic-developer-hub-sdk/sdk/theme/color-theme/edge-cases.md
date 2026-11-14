
- **Empty ansi array**: decoding and construction MUST succeed; `hasValidPalette` is false and `ansiColor(at: 0)` is nil.
- **More than 16 ansi colors**: decoding and construction MUST succeed; `hasValidPalette` is false; indices above 15 that exist in the array are still returned by `ansiColor(at:)`.
- **Negative or out-of-range index**: `ansiColor(at:)` MUST return nil and MUST NOT trap.
- **Both lock flags true**: `isEditable` is false and `isDeletable` is false (the built-in rule wins for deletion).
- **Unknown keys in JSON**: decoding MUST ignore them (the custom decoder reads only the known keys).
- **Malformed color string or wrong type**: decoding MUST throw and the theme is not produced; there is no partial theme.
- **Unknown appearance string**: decoding MUST throw, because `appearance` is required and `ThemeAppearance` accepts only its three raw values.
- **Unknown `roleOverrides` key**: stored as given; `ColorTheme` does not check keys against `ThemeRole`.
- **Boundary color components**: values outside 0 to 1 and non-finite values are clamped by `RGBAColor` before they reach the theme.
- **Concurrent access**: `ColorTheme` is a `Sendable` value type with no shared mutable state, so each copy is independent and no ordering rule applies.
- **Offline, cancellation, timeout**: not applicable; the type does no I/O and has no asynchronous operation.

