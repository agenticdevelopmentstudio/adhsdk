
Cursor shape

- **cursor-shape-cases**: `TerminalCursorShape` MUST have exactly four cases, in this order: `block`, `hollowBlock`, `underline`, `bar`.
- **cursor-shape-raw-value**: `TerminalCursorShape` MUST have a `String` raw value equal to the case name (`"block"`, `"hollowBlock"`, `"underline"`, `"bar"`) and MUST encode and decode as that string.
- **cursor-shape-traits**: `TerminalCursorShape` MUST be `Codable`, `CaseIterable`, `Sendable` and `Equatable`.
- **cursor-shape-no-blink**: `TerminalCursorShape` MUST NOT encode blinking. Blinking is the separate `cursorBlinks` field on `ThemeTerminalOptions`, because the user thinks of "block, blinking" as a shape plus a setting and SwiftTerm's six-case `CursorStyle` is an encoding detail.
- **cursor-shape-label**: `TerminalCursorShape.label` MUST return the literal picker text for each case: `"Block  ▉"`, `"Hollow Block  ▢"`, `"Underline  _"`, `"Bar  |"`. Each has two spaces before the glyph.
- **cursor-shape-decode-unknown**: Decoding a string that is not one of the four raw values MUST fail with the decoder's standard error; the source adds no fallback case.

Terminal options data shape

- **terminal-fields**: `ThemeTerminalOptions` MUST expose eight mutable optional fields: `paddingTop`, `paddingLeading`, `paddingBottom` and `paddingTrailing` (`Int?`), `fontName` (`String?`), `fontSize` (`Double?`), `cursorShape` (`TerminalCursorShape?`) and `cursorBlinks` (`Bool?`).
- **terminal-traits**: `ThemeTerminalOptions` MUST be `Codable`, `Equatable` and `Sendable`. Equality is the synthesized field-by-field comparison.
- **terminal-nil-means-settings**: A `nil` field in `ThemeTerminalOptions` MUST mean the Terminal settings panel value applies. The struct itself performs no resolution.
- **terminal-init-defaults**: The initializer `init(paddingTop:paddingLeading:paddingBottom:paddingTrailing:fontName:fontSize:cursorShape:cursorBlinks:)` MUST default every argument to `nil`, so `ThemeTerminalOptions()` is the no-opinion value.
- **terminal-font-name**: `fontName` MUST hold a PostScript font name, not a family name, because the font picker must tell `FiraCode Nerd Font Mono` from `FiraCode Nerd Font Propo`, which a family name cannot.
- **terminal-is-empty**: `ThemeTerminalOptions.isEmpty` MUST be true exactly when all eight fields are `nil`. It is the state every theme starts in and the one a "use the defaults" reset returns it to.
- **terminal-partial-override**: Setting one field MUST leave the other seven `nil`; a theme carries an opinion only about fields that were set.

Project options data shape

- **project-fields**: `ThemeProjectOptions` MUST expose three mutable optional fields: `highlightActivePane` (`Bool?`), `paneOutline` (`RGBAColor?`) and `paneBackdrop` (`RGBAColor?`).
- **project-traits**: `ThemeProjectOptions` MUST be `Codable`, `Equatable` and `Sendable`.
- **project-nil-means-settings**: A `nil` field in `ThemeProjectOptions` MUST mean the Projects settings panel (or the theme-derived default described next) applies. The struct performs no resolution.
- **project-init-defaults**: `init(highlightActivePane:paneOutline:paneBackdrop:)` MUST default every argument to `nil`.
- **project-highlight-switch**: `highlightActivePane` MUST override `UserSettings.highlightActivePane`, as the source comment states. The switch itself belongs in settings because it is a working preference; the theme overrides it and picks the color because that is an appearance decision.
- **project-outline-default**: When `paneOutline` is `nil`, the consumer MUST draw the theme's outline tone, which the source comment says is what the app draws when no theme has an opinion. The tone derivation is outside this file.
- **project-backdrop-default**: When `paneBackdrop` is `nil`, the consumer MUST use the theme's raised-surface tone, one step off the pane backdrop, so panes read as separate objects rather than one field with seams. The tone derivation is outside this file.
- **project-is-empty**: `ThemeProjectOptions.isEmpty` MUST be true exactly when all three fields are `nil`.

Codable

- **codable-synthesized**: Both structs use compiler-synthesized `Codable`: a keyed container whose keys are the property names, with a `nil` field omitted on encode and an absent or null key decoded as `nil`. The source writes no custom coding, so any JSON object, including `{}`, decodes.
- **codable-color-format**: `paneOutline` and `paneBackdrop` MUST encode as `"#RRGGBBAA"` strings, via `RGBAColor`'s single-value coding, and an unparseable string MUST fail the decode of the enclosing struct.
- **codable-type-mismatch**: A present value of the wrong type (for example a string for `paddingTop`) MUST fail the decode with the decoder's standard error. The source does not coerce.

Concurrency and side effects

- **sendable-values**: Both structs and the enum are `Sendable` value types; an instance copied to another thread MUST be independent of the original, and the source adds no locking.
- **no-side-effects**: No operation in this file MAY perform I/O, logging, notification or persistence. Persistence is the caller's, through `Codable` (the owning `ColorTheme` is stored by its own store).

