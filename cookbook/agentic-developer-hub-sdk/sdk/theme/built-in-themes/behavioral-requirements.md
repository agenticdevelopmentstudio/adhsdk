
### Catalogue composition

- **all-composition**: `BuiltInThemes.all` MUST equal `handAuthored` followed by `webPortedNative`, in that order, with `handAuthored` first.
- **all-count**: `BuiltInThemes.all` MUST contain 36 themes (15 hand-authored and 21 web-ported), as asserted by the `count` test.
- **hand-authored-order**: `BuiltInThemes.handAuthored` MUST list its 15 themes in this order: Solarized Dark, Solarized Light, Dracula, Nord, Tokyo Night, One Dark, Monokai Pro, Rosé Pine, Catppuccin Mocha, Catppuccin Latte, Ayu Dark, GitHub Dark, GitHub Light, Gruvbox Dark, Gruvbox Light.
- **hand-authored-appearance**: Among the hand-authored themes, 11 MUST declare `appearance` as `.dark` (Solarized Dark, Dracula, Nord, Tokyo Night, One Dark, Monokai Pro, Rosé Pine, Catppuccin Mocha, Ayu Dark, GitHub Dark, Gruvbox Dark) and 4 MUST declare `.light` (Solarized Light, Catppuccin Latte, GitHub Light, Gruvbox Light). None declares `.auto`.
- **hand-authored-scope**: `handAuthored` is internal to the module, not public. It MUST stay separate from `all` so tests about the app-chrome override promise can scope to the themes that make it. The web-ported themes carry chat overrides straight from the web CSS and let chrome derive.

### Theme identity

- **built-in-flag**: Every theme in `all` MUST have `isBuiltIn` equal to `true`.
- **unique-ids**: Every theme in `all` MUST have an `id` distinct from every other theme in `all`.
- **stable-ids**: Each theme's `id` MUST NOT change between releases. The doc comment states the IDs are stable UUID strings shared with the terminal feature's historical profile IDs, so persisted "active theme" selections survive upgrades.
- **hand-authored-id-scheme**: The hand-authored themes use IDs of the form `A1B2C3D4-00NN-4000-8000-0000000000NN`, where `NN` runs from 01 to 15 and is assigned by the theme's original position in the historical profile list, not by `handAuthored` order (for example Solarized Dark is 01, Solarized Light is 02, GitHub Light is 06, Gruvbox Dark is 07, Catppuccin Mocha is 08).
- **attribution-present**: Every hand-authored theme MUST carry a non-nil `attribution` naming the scheme's author or source (for example Solarized Dark carries "Ethan Schoonover").

### Default and lookup

- **default-id**: `BuiltInThemes.defaultID` MUST be the string `A1B2C3D4-0001-4000-8000-000000000001`, the ID of Solarized Dark.
- **default-resolves**: `theme(withID: BuiltInThemes.defaultID)` MUST return the theme named "Solarized Dark".
- **lookup-hit**: `theme(withID:)` MUST return the first theme in `all` whose `id` equals the argument.
- **lookup-miss**: `theme(withID:)` MUST return `nil` when no theme in `all` has that `id`.
- **lookup-exact-match**: `theme(withID:)` MUST compare the ID as an exact `String` equality, so a differently cased UUID string does not match.

### Palette data

- **ansi-count**: Every hand-authored theme MUST carry exactly 16 `ansi` colors, indices 0 to 7 normal and 8 to 15 bright, so `hasValidPalette` is true.
- **opaque-colors**: Every color a built-in constant supplies (foreground, background, cursor, selection, ansi entries, and role overrides) MUST be fully opaque, because `rgb(_:)` always appends the alpha byte `FF`.
- **hex-accuracy**: Hex literals MUST decode to the intended color. The `hexAccuracy` test pins Dracula background `282a36`, Dracula foreground `f8f8f2`, Dracula ANSI index 5 `ff79c6`, and Solarized Light background `fdf6e3`.
- **legibility**: For every theme in `all`, the `SemanticPalette` derived from it MUST give `primaryText` a contrast ratio of at least 4.0 against `windowBackground`, `secondaryText` at least 2.5 against `windowBackground`, and `onAccentText` at least 3.0 against `accent`. The `legibility` test asserts these thresholds.
- **distinct-surface**: For every theme in `all`, the derived `surface` color MUST differ from the derived `windowBackground` color.

### Chrome overrides

- **chrome-override-roles**: Each hand-authored theme's `roleOverrides` MUST contain an entry for each of `surface`, `elevatedSurface`, `controlBackground`, `border` and `outline`, keyed by `ThemeRole.rawValue`. The `chromeOverrides` test asserts this.
- **chrome-override-only**: The hand-authored themes MUST set no role override other than those five, leaving text, accent and status roles to derive from the palette.
- **chrome-builder**: The private `chrome(surface:elevated:control:border:outline:)` helper MUST map its `surface` argument to the `surface` role, `elevated` to `elevatedSurface`, `control` to `controlBackground`, `border` to `border` and `outline` to `outline`.

### Hex parsing

- **hex-optional-hash**: The private `rgb(_:)` helper MUST accept a six-digit hex string with or without a leading `#`.
- **hex-invalid-traps**: `rgb(_:)` MUST halt with `preconditionFailure("Invalid built-in theme hex: <input>")` when `RGBAColor(hexString:)` rejects the string. The source documents this as fail-fast at first use, with constants validated by `BuiltInThemesTests`. `hexString` rejects anything that is not exactly eight hex digits once `FF` is appended, so a three-digit or seven-digit literal traps.

### Concurrency and persistence

- **immutable-statics**: Every theme and list is a `static let` value constructed once, lazily, on first access (Swift's initialization of static stored properties is thread-safe). The type has no mutable state, so concurrent reads from any thread need no coordination.
- **no-side-effects**: The type MUST NOT write files, call the network, spawn processes or post notifications. It reads and writes nothing; persistence of the active theme selection belongs to `ThemeStore` and `ThemeStorage`.

