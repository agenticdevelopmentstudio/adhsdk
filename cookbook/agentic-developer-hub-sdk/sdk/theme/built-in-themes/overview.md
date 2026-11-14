
`BuiltInThemes` is a caseless Swift `enum` that acts as a namespace and static catalogue of the color themes the toolkit ships. It is the single source of truth for the bundled schemes: its doc comment states that the terminal feature derives its built-in profiles from this list (through `ColorTheme.terminalPalette`), so a theme is defined exactly once.

The catalogue has two parts. `handAuthored` is the original curated set of 15 themes. Each carries a 16-color terminal palette and explicit app-chrome role overrides (surface, elevated surface, control background, border, outline) taken from the scheme's own published panel and line colors. `all` is `handAuthored` followed by `webPortedNative`, the 21 themes ported from the web catalogue with their native adjustments (defined in `BuiltInThemes+Web.swift` and `BuiltInThemes+Native.swift`, which this recipe does not specify beyond how `all` composes them).

The type also exposes `defaultID` (Solarized Dark), `theme(withID:)` for lookup, and two private helpers: `chrome(...)`, which builds the five-role override dictionary, and `rgb(_:)`, which turns a hex literal into an opaque `RGBAColor`. Text, accent and status roles are not set here; they derive from the palette in `SemanticPalette`, which guarantees their contrast.

