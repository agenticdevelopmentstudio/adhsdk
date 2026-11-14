
**Decision**: Define each built-in theme once, here, and derive the terminal feature's profiles from this list.
**Rationale**: The doc comment calls this list the single source of truth, so a color edit cannot drift between the terminal and the rest of the app.
**Approved**: pending

**Decision**: Give the hand-authored themes explicit chrome overrides for surface, elevated surface, control background, border and outline instead of deriving them.
**Rationale**: The doc comment says the scheme's own published panel and line colors make panels and borders look authentic instead of muddy luminance blends. Text, accent and status roles still derive so `SemanticPalette` can guarantee their contrast.
**Approved**: pending

**Decision**: Keep `handAuthored` separate from `all`, and keep the web-ported themes off the chrome-override promise.
**Rationale**: The web-ported themes carry chat overrides from the web CSS and let chrome derive, so a test asserting chrome overrides must scope to the hand-authored set.
**Approved**: pending

**Decision**: Keep native-only adjustments in `BuiltInThemes+Native.swift`, applied over the generated web themes, rather than editing the generated file.
**Rationale**: The doc comment on `webPortedNative` says the web file is generated and must not be hand-edited, so a re-run of the generator cannot silently drop the adjustments.
**Approved**: pending

**Decision**: Make `rgb(_:)` trap on a malformed literal instead of returning an optional or a fallback color.
**Rationale**: The doc comment says built-in constants are validated by `BuiltInThemesTests` and a bad literal fails fast at first use, so a typo cannot ship as a silently wrong color. The cost is a crash for a bad constant; there is no recoverable path.
**Approved**: pending

**Decision**: Keep the stable, position-based ID scheme with its historical numbering, even where it differs from list order.
**Rationale**: The doc comment says the IDs are shared with the terminal feature's historical profile IDs so persisted active-theme selections survive upgrades; renumbering would orphan them.
**Approved**: pending

