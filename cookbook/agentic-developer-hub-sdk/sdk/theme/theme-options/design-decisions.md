
**Decision**: Every field is optional and `nil` means the settings panel decides.
**Rationale**: The source comment states a theme starts with no opinion and only acquires one for fields the user edits, so switching themes does not silently rewrite settings the user never touched (`principle-of-least-astonishment`).
**Approved**: pending

**Decision**: Cursor blinking is a separate `cursorBlinks` field, not extra enum cases.
**Rationale**: The source comment says "block, blinking" is how the user thinks about it and SwiftTerm's six-case `CursorStyle` is an encoding detail.
**Approved**: pending

**Decision**: `TerminalCursorShape` and both option structs live in the `AgenticDeveloperHubSDK` module, re-exported through `AgenticDeveloperHubSDKCore`, with the SwiftTerm mapping in the macOS framework.
**Rationale**: A `ColorTheme` carries one of each and the module is Foundation-only; the macOS framework is the only place that knows SwiftTerm exists.
**Approved**: pending

**Decision**: `fontName` is a PostScript name.
**Rationale**: The font picker must distinguish `FiraCode Nerd Font Mono` from `FiraCode Nerd Font Propo`, which share a family name.
**Approved**: pending

**Decision**: The active-pane switch lives in settings, while the theme overrides it and owns the color.
**Rationale**: The source comment calls the switch a working preference and the color an appearance decision.
**Approved**: pending

**Decision**: The `nil` backdrop is the theme's raised-surface tone, one step off the pane backdrop.
**Rationale**: The source comment says this makes panes read as separate objects rather than one field with seams.
**Approved**: pending

**Decision**: No value is validated and no decode fallback exists.
**Rationale**: The source is a plain data holder using synthesized coding; range checks and missing-font handling belong to the consumers. This is technical debt only in that a bad number from a hand-edited theme reaches rendering unchanged. A single bad optional override, such as an unknown cursor shape or a malformed color string, also fails the decode of the whole enclosing `ColorTheme`, so the user's entire theme is lost over one field; this is accepted because a lenient fallback would hide a corrupt file and the cost is confined to hand-edited or newer-version theme files.
**Approved**: pending


**Decision**: Keys the decoder does not know are dropped on the next save, and this forward-compatibility loss is accepted.
**Rationale**: The synthesized decoder ignores unknown keys, so a decode-then-save cycle is not idempotent for a theme file written by a newer version; keeping unknown keys would need custom coding that the source does not have.
**Approved**: pending
