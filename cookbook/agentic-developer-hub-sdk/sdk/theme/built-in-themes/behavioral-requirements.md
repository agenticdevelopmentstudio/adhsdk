
### Catalogue composition

- **all-composition**: `BuiltInThemes.all` MUST equal `handAuthored` followed by `webPortedNative`, in that order, with `handAuthored` first.
- **all-count**: `BuiltInThemes.all` MUST contain 15 hand-authored themes plus every theme that `webPortedNative` defines, as specified in Built-In Themes (Web Catalogue) ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.built-in-themes-web](cookbook:4b0159a7-3ee0-44d7-bd43-8b7ae5d64e8d)). The `count` test asserts the current total, 36 (15 plus 21); the sum, not the literal, is the requirement.
- **hand-authored-order**: `BuiltInThemes.handAuthored` MUST list its 15 themes in this order: Solarized Dark, Solarized Light, Dracula, Nord, Tokyo Night, One Dark, Monokai Pro, Rosé Pine, Catppuccin Mocha, Catppuccin Latte, Ayu Dark, GitHub Dark, GitHub Light, Gruvbox Dark, Gruvbox Light.
- **hand-authored-appearance**: Among the hand-authored themes, 11 MUST declare `appearance` as `.dark` (Solarized Dark, Dracula, Nord, Tokyo Night, One Dark, Monokai Pro, Rosé Pine, Catppuccin Mocha, Ayu Dark, GitHub Dark, Gruvbox Dark) and 4 MUST declare `.light` (Solarized Light, Catppuccin Latte, GitHub Light, Gruvbox Light). None declares `.auto`.
- **hand-authored-scope**: `handAuthored` MUST NOT be public (it is internal to the module). It MUST stay separate from `all` so tests about the app-chrome override promise can scope to the themes that make it. The web-ported themes carry chat overrides straight from the web CSS and let chrome derive.

### Theme identity

- **built-in-flag**: Every theme in `all` MUST have `isBuiltIn` equal to `true`.
- **unique-ids**: Every theme in `all` MUST have an `id` distinct from every other theme in `all`.
- **stable-ids**: Each theme's `id` MUST NOT change between releases. The IDs are stable UUID strings, shared with the terminal feature's historical profile IDs, so persisted "active theme" selections survive upgrades (see the comment on the `BuiltInThemes` enum in `BuiltInThemes.swift`).
- **hand-authored-id-scheme**: The hand-authored themes MUST use IDs of the form `A1B2C3D4-00NN-4000-8000-0000000000NN`, where `NN` runs from 01 to 15 and is assigned by the theme's original position in the historical profile list, not by `handAuthored` order (for example Solarized Dark is 01, Solarized Light is 02, GitHub Light is 06, Gruvbox Dark is 07, Catppuccin Mocha is 08).
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
- **legibility**: For every theme in `all`, the `SemanticPalette` derived from it MUST give `primaryText` a contrast ratio of at least 4.0 against `windowBackground`, `secondaryText` at least 2.5 against `windowBackground`, and `onAccentText` at least 3.0 against `accent`. The `legibility` test asserts these thresholds. The `primaryText` floor of 4.0 is below the WCAG AA level of 4.5:1 for body text; it is a known gap, recorded in Design Decisions.
- **distinct-surface**: For every theme in `all`, the derived `surface` color MUST differ from the derived `windowBackground` color.

### Chrome overrides

- **chrome-override-roles**: Each hand-authored theme's `roleOverrides` MUST contain an entry for each of `surface`, `elevatedSurface`, `controlBackground`, `border` and `outline`, keyed by `ThemeRole.rawValue`. The `chromeOverrides` test asserts this.
- **chrome-override-only**: The hand-authored themes MUST set no role override other than those five, leaving text, accent and status roles to derive from the palette.
- **chrome-builder**: In the Swift implementation, the private `chrome(surface:elevated:control:border:outline:)` helper maps its `surface` argument to the `surface` role, `elevated` to `elevatedSurface`, `control` to `controlBackground`, `border` to `border` and `outline` to `outline`. Observable result for any port: in each hand-authored theme the five chrome roles MUST receive five distinct values taken from the matching published colors, each in its own role (for example Solarized Dark `surface` `073642`, `elevatedSurface` `0a4250`, `controlBackground` `04313d`, `border` `0e4452`, `outline` `1d5b69`).

### Hex parsing

- **hex-optional-hash**: Informative, Swift only: the private `rgb(_:)` helper accepts a six-digit hex string with or without a leading `#`. A port MUST accept the same two forms in whatever helper builds the constants.
- **hex-invalid-traps**: Informative, Swift only: `rgb(_:)` halts with `preconditionFailure("Invalid built-in theme hex: <input>")` when `RGBAColor(hexString:)` rejects the string, so a malformed constant fails fast at first use (the comment on `rgb(_:)` in `BuiltInThemes.swift`). A port MUST fail fast, or fail a unit test, on a malformed constant. `hexString` rejects anything that is not exactly eight hex digits once `FF` is appended, so a three-digit or seven-digit literal traps.

### Concurrency and persistence

- **immutable-statics**: Every theme and list MUST be an immutable value constructed once, and the type MUST hold no mutable state, so concurrent reads from any thread need no coordination. In Swift each is a `static let`, initialized lazily on first access, which Swift performs thread-safely.
- **no-side-effects**: The type MUST NOT write files, call the network, spawn processes or post notifications. It reads and writes nothing; persistence of the active theme selection belongs to ThemeStore and ThemeStorage (cookbook:d15bba09-4574-4fd1-93a0-f7d2cccd04f2, cookbook:62abe97d-75f7-48c0-83cd-6df02a48515e), never to this type.

