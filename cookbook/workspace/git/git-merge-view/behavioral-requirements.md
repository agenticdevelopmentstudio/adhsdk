
### Rows

- **merge-side-rows**: Ours and theirs MUST be aligned row for row: each common line is one plain row on both; each conflict is its ours lines on the ours side and its theirs lines on the theirs side, the shorter side padded with `filler` rows (no text, no gutter number) to the longer's height.
- **merge-gutter-numbers**: Each side's gutter MUST number its rows with that side's own line numbers (the common lines with that side's conflict lines), fillers unnumbered; the result is numbered 1 to its row count. The gutter is one column, at least three digits wide.
- **merge-backgrounds**: An unchosen conflict's rows MUST be `emphasis` on both sides. Once chosen, the chosen side's rows are `added` and the other's plain: Ours marks ours, Theirs marks theirs, Both (either order) marks both, Base marks neither. Fillers stay `filler` throughout.
- **merge-result-rows**: The result pane MUST be the common lines (plain) with each chosen conflict's lines in place, `added`: Ours its ours lines, Theirs its theirs lines, Both ours then theirs (or theirs then ours), Base its base lines. An unchosen conflict is one empty `emphasis` row. With every conflict chosen, the result has exactly one row per line of `GitConflictDocument.resolved(_:)`.
- **merge-starts**: The layout MUST record each conflict's first row on the sides (`sideStarts`) and in the result (`resultStarts`), by conflict index.
- **merge-syntax**: The three texts (ours, theirs and base, each the common lines with that side's conflict lines, joined by newlines) MUST be coloured by the file's language through `GitSyntaxColoring`, off the main thread; each row takes its own line's runs in its side's text, the result's rows those of the text they came from. Rows show uncoloured until the colours land, and a later `show` drops an earlier one's colours.

### Controls

- **merge-show**: `show(path:document:)` MUST show the document with no choices made and the first conflict current, label the sides with the first conflict's marker labels (`Ours` and `Theirs` when a label is empty) and scroll to the first conflict. The scroll MUST happen whether `show` runs before or after the view is loaded: one the panes cannot take yet (no view, or no height) stays pending until the view is next laid out.
- **merge-navigation**: `Previous` and `Next` MUST move `currentConflict` by one, never past the first or the last, and scroll ours (and theirs with it) to `sideStarts[current]` and the result to `resultStarts[current]`. Previous is enabled while there is an earlier conflict, Next while there is a later one. The position label reads `<n> of <total>` (1-based).
- **merge-choose**: `Ours`, `Theirs` and `Both` MUST set the current conflict's choice to `.ours`, `.theirs` and `.oursThenTheirs`, and redraw all three panes. `Base` MUST set `.base` and is enabled only when the current conflict recorded a base.
- **merge-save**: `Save` MUST be enabled exactly while `resolved(choices)` is non-nil, and send `.save(path:text:)` with that exact text. `Cancel` MUST send `.cancel`.
- **merge-intents-only**: The view MUST NOT write the file or run git; saving, staging and closing are the delegate's.
- **merge-ui-thread**: The view MUST be used on the UI thread.
