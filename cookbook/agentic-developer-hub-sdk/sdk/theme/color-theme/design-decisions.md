
**Decision**: Decode `isBuiltIn`, `isImported`, `roleOverrides` and `typography` with defaults when absent, instead of failing.
**Rationale**: Source comments say hand-authored or third-party files lack the lock flags, the import path overwrites them, and themes persisted or exported by older builds predate the later fields. A custom `init(from:)` keeps those files loading.
**Approved**: pending

**Decision**: Keep `terminal` and `project` optional, with `nil` meaning the settings panel decides.
**Rationale**: The source comment calls absent "the meaningful state, not a migration fallback": a theme never given overrides has none.
**Approved**: pending

**Decision**: Do not validate the 16-color palette in the initializer or decoder; expose `hasValidPalette` and `ansiColorCount` instead.
**Rationale**: Validation is offered as a query, so the model can load any stored shape. The debt is that an invalid palette (and an unknown `roleOverrides` key) is accepted silently unless the caller asks. The only caller of `hasValidPalette` in source is `ThemeStore` import (`ThemeStore.swift`), which rejects an invalid palette with `ThemeImportError.invalidPalette`; theme builders such as `VSCodeThemeImporter` produce 16 colors by construction. Any new entry point that accepts a theme MUST check `hasValidPalette` itself.
**Approved**: pending

**Decision**: Imported themes are locked like built-ins but remain deletable.
**Rationale**: The source documents that locked themes are edited by duplicating; only built-ins are permanent. A duplicate carries both flags false and edits freely.
**Approved**: pending

**Decision**: Store semantic overrides as strings keyed by `ThemeRole.rawValue`.
**Rationale**: A string key keeps the persisted format stable if roles are added; roles without an override are derived from the palette by `SemanticPalette`, and overrides always win.
**Approved**: pending

