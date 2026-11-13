
**Decision**: Themes are filtered by the same licence list as grammars.
**Rationale**: A GPL-3.0 theme file shipped in the app carries the same obligation as a GPL-3.0 grammar; one rule for both keeps the licence position in one place.
**Approved**: pending

**Decision**: Licence texts come from the packages' NOTICE files, never from the network.
**Rationale**: The build must be a pure function of the lock file for `--check` to mean anything; every shipped item's NOTICE entry carries its text, and an item without one stops the build instead of shipping unlicensed.
**Approved**: pending

**Decision**: Contested extensions are settled by claim strength, then by a small explicit override table in the build script, and the build fails on any tie the table does not settle.
**Rationale**: linguist and tm-grammars spell scopes differently (`text.md` against `text.html.markdown`) and several linguist languages share a scope, so a scope-only join left Markdown, C++ and PHP with no extensions and gave `.ts` and `.rs` to XML. Name matching recovers them; an explicit table keeps the remaining judgement calls (`.h` is C) visible and reviewable, and failing on a new tie means a linguist update cannot silently reassign an extension.
**Approved**: pending

**Decision**: Colours are normalised to `#RRGGBB` or `#RRGGBBAA` inside the bundle.
**Rationale**: 27 shipped themes use `#RRGGBBAA`, `#RGB` or `#RGBA`; normalising once in JavaScript lets every host parse exactly two forms.
**Approved**: pending

**Decision**: Grammar and theme files are copied verbatim, not re-serialised.
**Rationale**: Their bytes stay identical to the pinned package, which keeps the checksums comparable with upstream and the diff of a version bump honest.
**Approved**: pending

