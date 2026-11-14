
Public surface: `ITermColorsParser.parse(data:name:id:appearance:)`, `ITermColorsParser.parse(contentsOf:name:id:appearance:)`, and the error enum `ITermColorsParseError` (`Error`, `Equatable`) with cases `notADictionary`, `missingColor(String)`, `missingComponent(colorKey:component:)` and `foregroundMatchesBackground`.

- **parse-data-returns-theme**: `parse(data:name:id:appearance:)` MUST return a `ColorTheme` built from the plist bytes, with `name` set to the supplied name.
- **parse-data-accepts-xml-and-binary**: `parse(data:)` MUST accept both XML and binary property-list encodings, since it delegates decoding to `PropertyListSerialization` with `format: nil`.
- **id-default-fresh-uuid**: When `id` is not supplied, the theme's `id` MUST be a fresh `UUID().uuidString`; when supplied, the theme's `id` MUST equal the supplied string.
- **not-built-in**: The returned theme MUST have `isBuiltIn` equal to `false`.
- **imported-flag-untouched**: The parser MUST NOT mark the theme imported; `isImported` keeps the `ColorTheme` initializer default. The caller (`ThemeStore.importITermColors`) sets it after parsing.
- **top-level-must-be-dictionary**: The parser MUST throw `ITermColorsParseError.notADictionary` when the decoded plist root is not a `[String: Any]` dictionary.
- **foreground-required**: The parser MUST throw `missingColor("Foreground Color")` when the top-level dictionary has no dictionary value under `Foreground Color`.
- **background-required**: The parser MUST throw `missingColor("Background Color")` when the top-level dictionary has no dictionary value under `Background Color`.
- **ansi-required**: The parser MUST read `Ansi 0 Color` through `Ansi 15 Color` (`ColorTheme.ansiColorCount`, 16) in index order and MUST throw `missingColor("Ansi N Color")` for the first absent index.
- **ansi-order-preserved**: The returned `ansi` array MUST hold exactly 16 colors, where element N is the color decoded from `Ansi N Color`.
- **component-required**: Within any required color dictionary, the parser MUST throw `missingComponent(colorKey:component:)` naming the color key and the first missing component among `Red Component`, `Green Component`, `Blue Component`, checked in that order.
- **component-type-strict**: A component present but not castable to `Double` (a plist `integer` is castable and is accepted) MUST be treated as missing and MUST throw `missingComponent`.
- **alpha-default-opaque**: When `Alpha Component` is absent or not a `Double`, the parser MUST use alpha `1.0`; a missing alpha MUST NOT raise an error.
- **extra-keys-ignored**: Keys the parser does not read (for example `Color Space`, `Bold Color`, `Link Color`, `Cursor Text Color`) MUST be ignored.
- **channel-clamping**: Every decoded channel MUST be clamped to 0 to 1, because each color is built through the `RGBAColor` initializer, which clamps its components.
- **foreground-equals-background-rejected**: The parser MUST throw `foregroundMatchesBackground` when the decoded foreground and background `RGBAColor` values are equal (all four channels, after clamping).
- **degenerate-check-before-ansi**: The foreground/background equality check MUST run after both colors decode and before any ANSI color is read, so an equal pair is reported even when the ANSI colors are missing.
- **cursor-fallback**: When `Cursor Color` is absent or fails to decode for any reason, the parser MUST use the foreground color as the cursor color and MUST NOT throw.
- **selection-fallback**: When `Selection Color` is absent or fails to decode for any reason, the parser MUST use `background.blended(withFraction: 0.25, of: foreground)` as the selection color and MUST NOT throw.
- **appearance-explicit-wins**: When `appearance` is non-nil, the theme's `appearance` MUST equal it exactly, including `.auto`.
- **appearance-inferred**: When `appearance` is `nil`, the theme's `appearance` MUST be `.dark` if `background.isDark` (relative luminance below 0.5, alpha ignored) and `.light` otherwise.
- **url-overload-reads-file**: `parse(contentsOf:name:id:appearance:)` MUST read the file with `Data(contentsOf:)` and delegate to `parse(data:name:id:appearance:)` with the other arguments unchanged.
- **url-overload-default-name**: When `name` is `nil`, the URL overload MUST use the file's base name, `url.deletingPathExtension().lastPathComponent` (`Dracula.itermcolors` becomes `Dracula`).
- **fail-fast**: The parser MUST stop at the first structural error and MUST NOT return a partial theme.
- **foundation-errors-propagate**: Errors from `PropertyListSerialization` (undecodable bytes) and from `Data(contentsOf:)` (unreadable file) MUST propagate to the caller unchanged and are not wrapped in `ITermColorsParseError`.
- **concurrency**: The parser holds no state; the two `parse` functions and the private `color(in:forKey:)` and `component(_:_:colorKey:)` helpers are static and pure apart from the URL overload's file read, so concurrent calls MAY run in parallel. Nothing in the source serialises or isolates them.
- **side-effects**: The data overload MUST have no side effect; the URL overload's only side effect is reading one file. The parser writes no files, makes no network calls, posts no notifications and logs nothing.

