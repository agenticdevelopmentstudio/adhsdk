
The module has no test file beside it. Vectors 1 to 5 come from the tests of its consumer in the adh package, `landingTypeScale.test.ts` (describe block "the first-load font contract"); the rest follow from the filter and map in the source and the committed manifest.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| fonts-001 | preload-flag-filter | Import `THEME_FONT_PRELOADS` (test "preloads at least the faces that carry a page layout") | length is greater than 0 |
| fonts-002 | same-origin, woff2-only | Every entry (test "preloads only same-origin woff2 paths") | matches `^/[^/]` and ends in `.woff2` |
| fonts-003 | css-agreement | Each entry against the css of the default adh theme (test "declares an @font-face for every preloaded face") | the css contains the entry wrapped in `url('...')` |
| fonts-004 | css-agreement | The css of the default theme (test "fetches no font from a third-party stylesheet") | it contains no `@import` statement |
| fonts-005 | no-validation | Each entry resolved by its file name against the themes package `src/fonts` directory (test "ships the preloaded bytes at the path it preloads") | the file exists for every entry |
| fonts-006 | preload-flag-filter, manifest-order, href-format | The committed manifest: publicPath `/fonts/bb398da1`, faces in order 400, 400-ext, 700, 700-ext, 400-italic, 400-italic-ext, flagged true, false, true, false, true, false | `["/fonts/bb398da1/iosevka-400.woff2", "/fonts/bb398da1/iosevka-700.woff2", "/fonts/bb398da1/iosevka-400-italic.woff2"]` |
| fonts-007 | core-cuts-only | The same manifest | no entry ends in `-ext.woff2` |
| fonts-008 | preload-flag-filter | A manifest in which no face has `preload` true | the list is empty |
| fonts-009 | href-format | A manifest with publicPath `/x` and one preloaded face file `a.woff2` | `["/x/a.woff2"]` |
| fonts-010 | no-validation | A preloaded face whose file is absent from disk | the href is still listed; no error is raised |

