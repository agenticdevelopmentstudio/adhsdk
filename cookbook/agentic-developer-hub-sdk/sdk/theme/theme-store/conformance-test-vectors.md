
Vectors are traced to `ThemeStoreTests` (suite `ThemeStore`) where a test exists; rows without a test name are derived from the source and unverified by a test.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-store-001 | no-cache, add-appends, lookup-by-id | `ThemeStoreTests.customThemeRoundTrips`: `add` a custom theme, then build a second `ThemeStore` over the same storage | The second store's `allThemes` contains the theme and `theme(withID:)` equals it |
| theme-store-002 | all-themes-order, custom-themes-read | `builtInsNeedNoStorage` and `startsWithBuiltIns`: a store over empty storage | `customThemes` is empty and `allThemes.count` equals `BuiltInThemes.all.count` |
| theme-store-003 | add-appends, is-built-in | `add` and `builtInDetection`: add one custom theme, then call `isBuiltIn` on `BuiltInThemes.defaultID` and the custom id | `customThemes.count` is 1, `allThemes.count` grows by 1, `isBuiltIn` is `true` for the default id and `false` for the custom id |
| theme-store-004 | update-replaces-by-id, update-noop-unknown | `update`: add a theme named Before, rename it to After and call `update`; then call `update` with Dracula renamed Hacked | The custom theme's name is After; Dracula's name stays Dracula |
| theme-store-005 | delete-removes-custom, delete-builtin-noop | `delete`: add a theme and delete its id; then delete `BuiltInThemes.defaultID` | The custom theme is gone; the built-in default is still found |
| theme-store-006 | delete-builtin-noop | `builtInsAreUndeletable`: delete the first built-in id | `allThemes` still contains it |
| theme-store-007 | delete-clears-active-id | Source-derived: storage with `activeThemeID` equal to a custom theme's id; call `delete(id:)` with that id | `storage.activeThemeID` is `nil` and the theme is gone |
| theme-store-008 | delete-builtin-noop | Source-derived: `activeThemeID` equals `BuiltInThemes.defaultID`; call `delete(id:)` with it | `allThemes` still holds the default; `activeThemeID` is unchanged (`deletingActiveBuiltInKeepsIt`) |
| theme-store-009 | delete-skips-noop-write | Source-derived: empty custom list; call `delete(id:)` with an unknown id | storage is not written and `activeThemeID` is unchanged |
| theme-store-010 | add-new-seed, add-new-identity, add-new-name | `addNew`: `addNewTheme(name: "Fresh")` | Name is Fresh, `isEditable` is `true`, `customThemes` contains it |
| theme-store-011 | unique-name, add-new-name | `addNewUniquifiesNames`: call `addNewTheme(name: "New Theme")` three times | Names are New Theme, New Theme 2, New Theme 3 |
| theme-store-012 | duplicate-copy, duplicate-name, duplicate-unlocks, duplicate-keeps-content | `duplicate`: `duplicate(BuiltInThemes.dracula)` | New id, `isBuiltIn` is `false`, name is Dracula Copy, `ansi` equals Dracula's, stored in `customThemes` |
| theme-store-013 | unique-name, duplicate-name | `duplicateUniquifiesNames`: add a theme named Base and duplicate it twice | Names are Base Copy and Base Copy 2 |
| theme-store-014 | duplicate-unlocks | `duplicateOfImportUnlocks`: export a sample, import it, duplicate the import | The copy has `isImported` and `isBuiltIn` both `false` and `isEditable` is `true` |
| theme-store-015 | duplicate-keeps-content | `duplicateKeepsAttribution` and `duplicatePreservesTypography`: duplicate a theme with attribution Somebody, `sizeScale` 1.4 and a Menlo body style | The copy has attribution Somebody and an equal `typography` |
| theme-store-016 | import-iterm-delegates, import-iterm-locked | `importITermColors` and `importITermMarksLocked`: write a valid XML plist named `Imported.itermcolors` and import it | Name is Imported, `isImported`, `isLocked` and `isDeletable` are `true`, and the theme is found by id |
| theme-store-017 | import-theme-sniffs-content | `importThemeSniffsContent`: ColorTheme JSON saved with a `.itermcolors` extension | `importTheme` imports it as JSON: name Mislabeled, `isImported` is `true` |
| theme-store-018 | import-theme-sniffs-content, import-theme-fallthrough | Source-derived: a JSON file with leading spaces, tab and newlines before `{`; and an empty file | The first imports as JSON; the empty file goes to the iTerm path and throws the parser's error with nothing stored |
| theme-store-019 | import-theme-read-error | Source-derived: `importTheme` on a URL that does not exist | The `Data(contentsOf:)` error is thrown and `customThemes` is unchanged |
| theme-store-020 | import-json-fresh-id, import-json-flags, import-json-stores | `jsonRoundTripLocks`: `exportJSON` then `importJSON(data:)` | New id differs from the source, name is Shared, the import is locked and deletable, and it is found by id |
| theme-store-021 | import-json-flags | `importJSONSanitizesBuiltIn`: export a theme with `isBuiltIn` true and import it | `isBuiltIn` is `false`, `isImported` is `true`, `isDeletable` is `true` |
| theme-store-022 | import-json-palette, import-json-atomic, import-error-text | `importJSONRejectsShortPalette`: JSON with 3 ANSI colors | `ThemeImportError` is thrown, `customThemes` is empty, and the message reads `This theme has 3 ANSI colors; a valid theme needs exactly 16.` |
| theme-store-023 | import-json-visible-text, import-json-atomic, import-error-text | `importJSONRejectsInvisibleText`: 16 ANSI colors, foreground and background both `#000000ff` | `ThemeImportError` is thrown and `customThemes` is empty; the message names the same-color problem |
| theme-store-024 | import-json-decode, import-json-stores | `importJSONAcceptsValid`: well-formed 16-color JSON named Good | Returns a theme named Good with `hasValidPalette` and `isImported` true |
| theme-store-025 | import-json-decode, import-json-atomic | Source-derived: `importJSON(data:)` with the bytes of `not json` | A `DecodingError` propagates and nothing is stored |
| theme-store-026 | import-json-clamps-scale | Source-derived: valid JSON with `sizeScale` 0, then another with 9 | The stored `typography.sizeScale` is 0.5 and 4 respectively; both imports succeed (a non-finite scale would become 1.0) |
| theme-store-027 | import-json-check-order | Source-derived: JSON with 3 ANSI colors and equal foreground and background | `invalidPalette(count: 3)` is thrown, not `foregroundMatchesBackground` |
| theme-store-028 | import-json-url | Source-derived: write a valid ColorTheme JSON to a file and call `importJSON(contentsOf:)`; call it on a missing file | The first stores a locked import; the second throws the read error |
| theme-store-029 | export-json-format, export-json-roundtrip | Source-derived: `exportJSON` of a theme | The bytes are pretty-printed with keys in sorted order and decode back to an equal `ColorTheme` |
| theme-store-030 | lookup-by-id, add-unvalidated | Source-derived: `add` a theme carrying a built-in's id | `theme(withID:)` returns the built-in, and `customThemes` holds both entries without error |
| theme-store-031 | import-iterm-name-not-uniquified | Source-derived: import an `.itermcolors` file whose base name matches an existing theme | The stored name equals the existing name with no numeric suffix |
| theme-store-032 | storage-injected, main-actor-isolation, no-timeout-no-retry, write-failure-silent | `ThemeStoreTests` construction: `ThemeStore(storage: InMemoryThemeStorage())` on the main actor | Every call completes synchronously and no storage error is surfaced by the store |

