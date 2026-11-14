
- **Empty storage** (MUST): a fresh install has no custom themes; `allThemes` is the built-ins alone and `theme(withID:)` returns `nil` for an unknown id.
- **Unknown id on update** (MUST): `update(_:)` does nothing and does not write to storage.
- **Unknown id on delete** (MUST): `delete(id:)` returns without writing storage or touching `activeThemeID`.
- **Deleting the active custom theme** (MUST): `activeThemeID` becomes `nil`, so a later import that reuses the id cannot silently become active.
- **Deleting a built-in id** (MUST): the built-in stays in the catalog; `activeThemeID` is left alone even when it names that built-in.
- **Id collisions through `add`** (SHOULD NOT be relied on): `add` accepts a theme whose id matches a built-in or custom theme; the built-in then shadows it in `theme(withID:)`. The import paths avoid this by assigning fresh ids.
- **Name collisions** (MUST): `addNewTheme` and `duplicate` add a numeric suffix starting at 2; `add` and the import paths keep the name as given.
- **Malformed JSON, wrong shape, or missing fields** (MUST): the `JSONDecoder` error propagates and nothing is stored.
- **ANSI count other than 16** (MUST): rejected with `invalidPalette(count:)`, including 0 and more than 16.
- **Foreground equal to background** (MUST): rejected with `foregroundMatchesBackground`; the comparison is whole-color equality.
- **sizeScale outside 0.5 to 4** (MUST): repaired by clamping, not rejected; a scale of 0 becomes 0.5, and a non-finite scale becomes 1.0.
- **Mislabeled file** (MUST): the first non-whitespace byte decides the importer, so a JSON file named `.itermcolors` and a plist named `.json` both import.
- **Binary or XML plist, or any non-`{` content** (MUST): handed to `ITermColorsParser`, whose errors surface; the file is read a second time on that path.
- **Missing or unreadable file** (MUST): the `Data(contentsOf:)` or parser read error propagates.
- **Concurrent access**: calls are serialised by `@MainActor`; an external storage change between two calls is not detected (see Behavioral Requirements, Concurrency).
- **Storage failure**: not surfaced; the setters cannot throw, so a conformer that fails to persist loses the write silently from the store's point of view (`write-failure-silent`).
- **Offline or disconnected state**: not applicable — the store reads local files and an injected local storage and makes no network request.
- **Cancellation and timeout**: not applicable — every call is synchronous with no suspension point.

