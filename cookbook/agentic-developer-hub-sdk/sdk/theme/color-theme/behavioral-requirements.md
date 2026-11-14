
### ThemeAppearance

- **appearance-cases**: `ThemeAppearance` MUST have exactly three cases, `dark`, `light` and `auto`, each encoded as its lowercase name.
- **appearance-identifier**: `ThemeAppearance.id` MUST equal its raw value.
- **appearance-enumerable**: `ThemeAppearance` MUST be enumerable as a collection of all cases and MUST be safe to share across concurrency domains.

### ColorTheme data shape

- **theme-value-type**: `ColorTheme` MUST be a value type that is `Codable`, `Identifiable`, `Equatable` and safe to share across concurrency domains, identified by its `id` string.
- **identity-fields**: `ColorTheme` MUST carry `id` (String), `name` (String), `appearance` (`ThemeAppearance`), `isBuiltIn` (Bool), `isImported` (Bool) and `attribution` (optional String).
- **palette-fields**: `ColorTheme` MUST carry `foreground`, `background`, `cursor` and `selection` as `RGBAColor`, and `ansi` as an array of `RGBAColor` holding indices 0 to 15 (0 to 7 normal, 8 to 15 bright).
- **role-overrides-field**: `ColorTheme` MUST carry `roleOverrides` as a dictionary from `ThemeRole.rawValue` strings to `RGBAColor`.
- **role-overrides-precedence**: A role present in `roleOverrides` MUST win over the value derived from the palette. `ColorTheme` only stores the overrides; the derivation and the precedence are implemented by `SemanticPalette`, named in the source doc comment.
- **typography-field**: `ColorTheme` MUST carry `typography` as a `ThemeTypography`, defaulting to `ThemeTypography.system`.
- **feature-override-fields**: `ColorTheme` MUST carry `terminal` (optional `ThemeTerminalOptions`) and `project` (optional `ThemeProjectOptions`). `nil` MUST mean the Terminal or Projects settings panel decides.
- **color-encoding**: Every color field MUST encode as an `#RRGGBBAA` hex string through `RGBAColor`, and a malformed hex string MUST fail decoding with a data-corrupted error (behavior of `RGBAColor`, which clamps constructed components to the range 0 to 1).

### Initialization

- **init-defaults**: The memberwise initializer MUST default `id` to a fresh `UUID().uuidString`, `isBuiltIn` and `isImported` to `false`, `attribution` to `nil`, `roleOverrides` to an empty dictionary, `typography` to `.system`, and `terminal` and `project` to `nil`.
- **init-required**: The memberwise initializer MUST require `name`, `appearance`, `foreground`, `background`, `cursor`, `selection` and `ansi`.
- **init-no-validation**: The initializer MUST NOT validate the palette; a theme with any number of `ansi` colors can be constructed.

### Decoding

- **decode-required-keys**: Decoding MUST fail when any of `id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `selection` or `ansi` is absent.
- **decode-lock-flags-default**: Decoding MUST treat an absent `isBuiltIn` or `isImported` as `false`. A hand-authored theme file does not carry them, and the import path overwrites them anyway.
- **decode-attribution-default**: Decoding MUST treat an absent `attribution` as `nil`.
- **decode-role-overrides-default**: Decoding MUST treat an absent `roleOverrides` as an empty dictionary.
- **decode-typography-default**: Decoding MUST treat an absent `typography` as `.system`, so themes persisted before typography existed still load.
- **decode-feature-options-absent**: Decoding MUST treat an absent `terminal` or `project` as `nil`. Absent is the meaningful state, not a migration fallback.
- **decode-no-palette-validation**: Decoding MUST NOT reject an `ansi` array whose length is not 16; length is checked by callers through `hasValidPalette`.
- **codable-round-trip**: Encoding a theme and decoding the result MUST yield an equal theme, provided each color sits on the 8-bit grid.

### Derived properties

- **ansi-color-count**: `ColorTheme.ansiColorCount` MUST be `16`.
- **has-valid-palette**: `hasValidPalette` MUST be `true` exactly when `ansi.count` equals `ansiColorCount`.
- **ansi-color-lookup**: `ansiColor(at:)` MUST return the color at the index when it is within `ansi.indices`, and `nil` for any other index, including negative ones.
- **is-editable**: `isEditable` MUST be `true` exactly when `isBuiltIn` and `isImported` are both `false`.
- **is-locked**: `isLocked` MUST be the inverse of `isEditable`.
- **is-deletable**: `isDeletable` MUST be `true` exactly when `isBuiltIn` is `false`, so imported and custom themes can be deleted and built-ins never can.
- **duplicate-is-custom**: A duplicate of a locked theme is a plain custom theme (`isBuiltIn == false`, `isImported == false`) and is editable. `ColorTheme` expresses this only through the flag logic; the duplicate operation lives in the caller.

### Ordering and side effects

- **no-side-effects**: Every operation of `ColorTheme` MUST be synchronous and free of side effects (no files, network, notifications or logging). Persistence is the job of `ThemeStorage`.

