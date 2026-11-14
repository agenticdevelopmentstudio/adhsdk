
**Decision**: Register themes in a hand-written record whose `ThemeKey` union is maintained separately from it.
**Rationale**: Inferred from the source: the union gives consumers literal-type keys, and `Record<ThemeKey, ThemeEntry>` makes the compiler enforce that every key has an entry. The cost is that each key is written three times and `id` is not tied to the record key.
**Approved**: pending

**Decision**: Derive `themeIds` from `Object.keys(themes)` instead of a second hand-kept array.
**Rationale**: The source derives it, so the list cannot drift from the record; it follows declaration order, which is why the keys are not alphabetical.
**Approved**: pending

**Decision**: Hold stylesheet text as imported strings from a generated `theme-data` module instead of loading files at run time.
**Rationale**: The `ThemeStyle` comment says the style element is rendered inline so it is in the server-rendered HTML and applied on first paint; bundling the text makes that possible. The cost is that every theme is loaded with the manifest.
**Approved**: pending

**Decision**: Make registration the gate for a theme to exist.
**Rationale**: The `rescued-themes.test.ts` comment states a stylesheet on disk is invisible until it is registered, so the manifest is the one place to add a theme.
**Approved**: pending

