
Public surface: `ThemeStore.init(storage:)`, `customThemes`, `allThemes`, `theme(withID:)`, `isBuiltIn(id:)`, `add(_:)`, `update(_:)`, `delete(id:)`, `addNewTheme(basedOn:name:)`, `duplicate(_:nameSuffix:)`, `importITermColors(contentsOf:)`, `importTheme(contentsOf:)`, `importJSON(contentsOf:)`, `importJSON(data:)`, `exportJSON(_:)`, and the error enum `ThemeImportError` (`LocalizedError`) with cases `invalidPalette(count:)` and `foregroundMatchesBackground`. The mutators that return a `ColorTheme` are `@discardableResult`.

- **main-actor-isolation**: `ThemeStore` MUST be isolated to the main actor, so every call is serialised on one actor.
- **storage-injected**: `ThemeStore` MUST receive its `ThemeStorage` through `init(storage:)` and MUST NOT create or choose a storage itself.
- **no-cache**: `ThemeStore` MUST NOT cache themes; each read of `customThemes`, `allThemes`, `theme(withID:)` or `isBuiltIn(id:)` MUST reflect what the storage holds at that moment, so a second store over the same storage sees every earlier write.
- **custom-themes-read**: `customThemes` MUST return `storage.customThemes` unchanged, in storage (insertion) order.
- **all-themes-order**: `allThemes` MUST return `BuiltInThemes.all` followed by `customThemes`, so an empty storage still yields the full built-in catalog.
- **lookup-by-id**: `theme(withID:)` MUST return the first theme in `allThemes` whose `id` matches, or `nil` when none does. Because built-ins come first, a built-in wins over a custom theme that shares its id.
- **is-built-in**: `isBuiltIn(id:)` MUST return `true` exactly when `BuiltInThemes.theme(withID:)` finds the id, and `false` for custom and unknown ids.
- **add-appends**: `add(_:)` MUST set `storage.customThemes` to the current custom themes followed by the given theme and MUST return that theme.
- **add-unvalidated**: `add(_:)` MUST NOT validate the theme: it checks neither the palette length, nor id collisions with built-ins or custom themes, nor name uniqueness. Validation lives in the import paths.
- **update-replaces-by-id**: `update(_:)` MUST replace the custom theme that has the same `id` in place, keeping its position, and write the list back to storage.
- **update-noop-unknown**: `update(_:)` MUST do nothing, and MUST NOT write to storage, when no custom theme has the given `id`; this includes every built-in id.
- **delete-removes-custom**: `delete(id:)` MUST remove every custom theme with the given `id` and write the filtered list to storage.
- **delete-clears-active-id**: `delete(id:)` MUST set `storage.activeThemeID` to `nil` when it equals the given `id`, so storage never keeps pointing at a removed theme.
- **delete-builtin-noop**: `delete(id:)` MUST be a no-op when `id` names no custom theme, built-ins included: it writes nothing and leaves `activeThemeID` alone even when that id is the active theme. Covered by `builtInsAreUndeletable` and `deletingActiveBuiltInKeepsIt`.
- **delete-skips-noop-write**: `delete(id:)` MUST NOT write storage when no custom theme matched, so an unknown or built-in id leaves `customThemes` and `activeThemeID` untouched.
- **add-new-seed**: `addNewTheme(basedOn:name:)` MUST copy the template, defaulting to `BuiltInThemes.solarizedDark`, so the new theme keeps the template's palette, typography and other fields.
- **add-new-identity**: `addNewTheme` MUST give the copy a fresh `UUID().uuidString` id, set `isBuiltIn` and `isImported` to `false`, set `attribution` to `nil`, and store it through `add(_:)`.
- **add-new-name**: `addNewTheme` MUST name the copy `uniqueName(name)`, with `name` defaulting to `"New Theme"`.
- **unique-name**: The private `uniqueName(_:)` MUST return `base` when no theme in `allThemes` (built-in or custom) has that name; otherwise it MUST return `base` followed by a space and the smallest integer 2 or greater that makes the name unused.
- **duplicate-copy**: `duplicate(_:nameSuffix:)` MUST copy any theme (built-in, imported or custom), give the copy a fresh `UUID().uuidString` id, and store it through `add(_:)`.
- **duplicate-name**: `duplicate` MUST name the copy `uniqueName(theme.name + nameSuffix)`, with `nameSuffix` defaulting to `" Copy"`.
- **duplicate-unlocks**: `duplicate` MUST set `isBuiltIn` and `isImported` to `false` on the copy, so a copy of a locked theme is editable.
- **duplicate-keeps-content**: `duplicate` MUST keep the source theme's palette, typography and `attribution` on the copy.
- **import-iterm-delegates**: `importITermColors(contentsOf:)` MUST parse the file with `ITermColorsParser.parse(contentsOf:)`, so the theme name is the file's base name and parser errors propagate to the caller.
- **import-iterm-locked**: `importITermColors` MUST set `isImported` to `true` on the parsed theme and store it through `add(_:)`, returning the stored theme.
- **import-iterm-name-not-uniquified**: `importITermColors` MUST NOT disambiguate the theme name, so an import can share a name with an existing theme.
- **import-theme-sniffs-content**: `importTheme(contentsOf:)` MUST read the file bytes and choose the importer by content, not extension: when the first byte that is not one of 0x20, 0x09, 0x0A or 0x0D is `{` (0x7B) it MUST import as JSON, and otherwise it MUST import through `importITermColors(contentsOf:)`.
- **import-theme-read-error**: `importTheme` MUST propagate the error thrown when the file cannot be read, and MUST store nothing.
- **import-theme-fallthrough**: `importTheme` MUST send an empty or all-whitespace file to the `.itermcolors` path, where the parser's error surfaces.
- **import-json-url**: `importJSON(contentsOf:)` MUST read the file with `Data(contentsOf:)` and delegate to `importJSON(data:)`, propagating the read error.
- **import-json-decode**: `importJSON(data:)` MUST decode the bytes as a `ColorTheme` with `JSONDecoder`, and MUST propagate the decoding error unchanged when the JSON is malformed or incomplete.
- **import-json-palette**: `importJSON(data:)` MUST throw `ThemeImportError.invalidPalette(count:)` carrying the decoded `ansi.count` when the decoded theme does not have exactly `ColorTheme.ansiColorCount` (16) ANSI colors.
- **import-json-visible-text**: `importJSON(data:)` MUST throw `ThemeImportError.foregroundMatchesBackground` when the decoded `foreground` equals the decoded `background`.
- **import-json-check-order**: `importJSON(data:)` MUST check the palette length before the foreground and background comparison, so a theme failing both reports `invalidPalette`.
- **import-json-atomic**: `importJSON(data:)` MUST store nothing when any decode or validation step throws.
- **import-json-clamps-scale**: `importJSON(data:)` MUST clamp `typography.sizeScale` into `ThemeTypography.sizeScaleRange` (0.5 to 4) through `ThemeTypography.clampedSizeScale`, which maps a non-finite value (NaN or an infinity) to `1.0`, and MUST NOT reject the theme for a scale outside the range.
- **import-json-fresh-id**: `importJSON(data:)` MUST replace the file's `id` with a fresh `UUID().uuidString`, so an import cannot collide with or shadow a built-in or an existing custom theme.
- **import-json-flags**: `importJSON(data:)` MUST set `isBuiltIn` to `false` and `isImported` to `true`, whatever the file declares, so an import is locked, never permanent, and deletable.
- **import-json-stores**: `importJSON(data:)` MUST store the sanitised theme through `add(_:)` and return it, keeping the file's name and every other field unchanged.
- **export-json-format**: `exportJSON(_:)` MUST encode the given theme with `JSONEncoder` using `prettyPrinted` and `sortedKeys` output formatting and MUST return the bytes.
- **export-json-roundtrip**: The `exportJSON` output MUST be accepted by `importJSON(data:)` when the theme has 16 ANSI colors and distinct foreground and background; the exported `id` and lock flags are not preserved on import.
- **export-json-errors**: `exportJSON` MUST propagate any `JSONEncoder` error and MUST NOT touch storage.
- **import-error-text**: `ThemeImportError.errorDescription` MUST be `This theme has N ANSI colors; a valid theme needs exactly 16.` for `invalidPalette(count: N)` and `This theme's foreground and background are the same color, so its text would be invisible.` for `foregroundMatchesBackground`.
- **no-timeout-no-retry**: `ThemeStore` MUST NOT add a timeout, retry or cancellation to any call; every operation is synchronous and runs to completion on the main actor, including the file reads.
- **write-failure-silent**: `ThemeStore` MUST NOT report storage write failures, because the `ThemeStorage` setters are non-throwing and the store checks nothing after a write; durability belongs to the injected conformer (`UserDefaultsThemeStorage` for the default host).

Concurrency: the type is `@MainActor`, and every method is synchronous, so each read-modify-write (`add`, `update`, `delete`) runs without interleaving with another store call. A change made to the storage from outside the store (a settings panel, a sync from another device) can land between two calls; the store does not detect it, and the next call reads the new value. `ThemeStorage.onExternalChange` is how a host learns of that, and `ThemeStore` never sets or invokes it.

Persistence: nothing is persisted by the store itself. Custom themes and `activeThemeID` survive a restart only to the extent the injected `ThemeStorage` round-trips them, which the protocol requires of every conformer. Built-ins are never stored, and the ephemeral data is the store instance itself.

