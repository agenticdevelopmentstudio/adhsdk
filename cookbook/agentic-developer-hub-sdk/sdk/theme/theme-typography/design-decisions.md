
**Decision**: Fonts are read by role (`TextRole`), not by name or size, and each role resolves to a `FontStyle`.
**Rationale**: The source says a label's meaning survives a theme swap and a global size change when UI reads fonts by role, the same way it reads colors by `ThemeRole`.
**Approved**: pending

**Decision**: `styles` is a `[String: FontStyle]` keyed by `TextRole.rawValue` instead of a `[TextRole: FontStyle]`.
**Rationale**: The source says this mirrors `ColorTheme.roleOverrides` and round-trips cleanly through `Codable` and `UserDefaults`; a string key encodes as a JSON object, an enum key as an array. The cost is that a stray key is accepted silently (`styles-unknown-key`).
**Approved**: pending

**Decision**: A role missing from `styles` falls back to `defaultStyle(_:)`, and an override replaces the whole `FontStyle`.
**Rationale**: The source says the empty `ThemeTypography()` reproduces the app's current system-font look exactly. Replacement is the simplest lookup (`styles[rawValue] ?? default`); the consequence is that a partial override does not inherit the role's default weight or monospacing.
**Approved**: pending

**Decision**: `sizeScale` is a global multiplier applied at read time in `size(_:)`, and the stored `FontStyle.size` is never changed.
**Rationale**: The source says a user can make the whole app larger or smaller without editing each role. The theme's `sizeScale` is the designer's (for example 1.0667 for `old-school-terminal`, because VT323 draws small for its point size), while the reader's "Text Size" factor is separate, applied in `SemanticPalette.scaled(by:)`, so it survives a theme change.
**Approved**: pending

**Decision**: The 0.5 to 4 clamp is a shared static (`sizeScaleRange`, `clampedSizeScale(_:)`) applied by callers and not by `init` or `size(_:)`.
**Rationale**: The source says it is the one place both callers enforce the limit so they cannot drift. It is not enforced in `init` because a decoded or hand-built value is the caller's to repair; `ThemeStore.importJSON` repairs rather than refuses since a bad scale leaves the theme mis-sized, not unusable. The consequence is that a `ThemeTypography` built directly can hold any scale.
**Approved**: pending

**Decision**: `defaultStyle(_:)` uses AppKit's standard metrics (22, 15, 13, 11, 12 monospaced, 13 medium).
**Rationale**: The source says an uncustomized theme should look like the app does today. A port to another platform copies the numbers for parity but may keep its own native metrics when native look is wanted.
**Approved**: pending

