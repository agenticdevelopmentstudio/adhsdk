
### Exports

- **preload-list-export**: The module MUST export `THEME_FONT_PRELOADS` as a read-only array of strings (`readonly string[]`).
- **single-export**: The module MUST export no other runtime value; the manifest is imported but not re-exported.
- **computed-at-load**: The list MUST be computed once when the module is evaluated, from the manifest imported at that time.

### Selection

- **preload-flag-filter**: The list MUST contain exactly the manifest faces whose `preload` flag is truthy, and no face whose flag is false.
- **manifest-order**: The list MUST keep the order in which the faces appear in the manifest `faces` array.
- **core-cuts-only**: The faces flagged for preload MUST be the three CORE cuts (regular 400, bold 700 and italic 400); the EXT cuts MUST NOT be flagged, because `unicode-range` already keeps them unfetched until a page paints a codepoint in their range.
- **italic-included**: The italic 400 CORE cut MUST be in the list, because the `SiteLanding` heading sets its accent word in italic above the fold.

### Href shape

- **href-format**: Each entry MUST be the manifest `publicPath`, a slash, then the face `file` (for example `/fonts/bb398da1/iosevka-400.woff2`).
- **same-origin**: Each entry MUST be a root-relative path beginning with a single slash; it MUST NOT carry a scheme or host, since the preload is only worth emitting because the fetch rides the connection that delivered the html.
- **woff2-only**: Each entry MUST end in `.woff2`.
- **css-agreement**: Each entry MUST appear as the url of an `@font-face` in the css of the default adh theme built from the same manifest (the css emitted by `scripts/build-tokens.mjs`, as asserted by the adh consumer test).
- **no-validation**: The module MUST NOT validate the manifest, check that files exist, or filter on the file name; correctness of paths rests on the manifest generator and on the consumer's tests.

### Side effects and concurrency

- **no-side-effects**: Importing the module MUST NOT touch the network, the file system or the document; it only reads the bundled manifest.
- **immutable-value**: The value is computed once and never mutated by the module, so concurrent readers see the same list. Module evaluation is single-threaded.

