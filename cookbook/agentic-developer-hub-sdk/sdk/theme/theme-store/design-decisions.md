
**Decision**: The store caches nothing and reads the injected storage on every call.
**Rationale**: A change made to the storage elsewhere (a settings panel, a sync) is then visible to the next call without invalidation, and the test `customThemeRoundTrips` relies on a second store over the same storage seeing the first store's writes.
**Approved**: pending

**Decision**: `delete(id:)` clears `activeThemeID` when it equals the deleted id.
**Rationale**: The doc comment explains that a stale id can never be satisfied by `reload()` and would snap back to active if a later import reused it. The method returns early when no custom theme matched, so a built-in id (or an unknown one) never writes storage or clears the active id, keeping the "no-op for built-ins" promise.
**Approved**: pending

**Decision**: `importJSON(data:)` replaces the id, forces `isBuiltIn` off and `isImported` on, and validates the palette and foreground against background.
**Rationale**: The doc comment says a hand-edited or malicious file must not shadow a built-in, become un-deletable, or enter the catalog as an unusable theme; a short ANSI array traps consumers that index all 16 slots, and equal colors make every glyph invisible.
**Approved**: pending

**Decision**: An out-of-range `typography.sizeScale` is clamped to 0.5 to 4 instead of rejected.
**Rationale**: The doc comment says a bad scale leaves the theme usable but mis-sized, so it is repaired; the same `ThemeTypography.clampedSizeScale` bounds `SemanticPalette.scaled(by:)` so the two limits cannot drift.
**Approved**: pending

**Decision**: `importTheme(contentsOf:)` chooses the parser from the first non-whitespace byte, not the file extension.
**Rationale**: The doc comment states that a mis-named file still imports; a JSON theme starts with `{` and an `.itermcolors` plist starts with `<` or `b`. The plist path therefore reads the file twice, once to sniff and once in the parser.
**Approved**: pending

**Decision**: Imports are locked (`isImported`), duplicates are unlocked, and only `addNewTheme` and `duplicate` disambiguate names.
**Rationale**: Locked imports keep shared themes intact while duplication is the way to customise them; repeated add and duplicate actions would otherwise stack indistinguishable rows, per the `uniqueName` doc comment. Imports keep the file's own name.
**Approved**: pending

**Decision**: `add(_:)` and `update(_:)` do not validate the theme.
**Rationale**: The editor and the factory methods are the callers that build themes; validation sits at the import boundary where untrusted data enters. The source states no further reason.
**Approved**: pending

