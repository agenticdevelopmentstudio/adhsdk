
The module has no test file beside it. Vectors 1 to 5 come from the tests of its consumer in the adh package, `landingTypeScale.test.ts` (describe block "the first-load font contract"); the rest follow from the filter and map in the source and the committed manifest. Vectors 001 to 005 and 007 exercise the manifest, the css build or the consumer, so they are integration vectors; vectors 008 to 010 are tested in `fonts.test.ts` in the themes package `__tests__` folder, using injected manifests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| fonts-001 | preload-flag-filter (integration: committed manifest) | Import `THEME_FONT_PRELOADS` (test "preloads at least the faces that carry a page layout") | length is greater than 0 |
| fonts-002 | same-origin, woff2-only | Every entry (test "preloads only same-origin woff2 paths") | matches `^/[^/]` and ends in `.woff2` |
| fonts-003 | css-agreement | Each entry against the css of the default adh theme (test "declares an @font-face for every preloaded face") | the css contains the entry wrapped in `url('...')` |
| fonts-004 | css-agreement | The css of the default theme (test "fetches no font from a third-party stylesheet") | it contains no `@import` statement |
| fonts-005 | integration: materialization places the bytes (the module itself checks nothing, per no-validation) | Each entry resolved by its file name against the themes package `src/fonts` directory (test "ships the preloaded bytes at the path it preloads") | the file exists for every entry |
| fonts-006 | preload-flag-filter, manifest-order, href-format | A fixture manifest with publicPath `/p` and faces `iosevka-400.woff2`, `iosevka-400-ext.woff2`, `iosevka-700.woff2` flagged true, false, true | `["/p/iosevka-400.woff2", "/p/iosevka-700.woff2"]`, in manifest order; against the committed manifest, every entry starts with its `publicPath` |
| fonts-007 | core-cuts-only (integration: manifest generator) | The committed manifest | no entry ends in `-ext.woff2` |
| fonts-008 | preload-flag-filter | A manifest in which no face has `preload` true | the list is empty |
| fonts-009 | href-format | A manifest with publicPath `/x` and one preloaded face file `a.woff2` | `["/x/a.woff2"]` |
| fonts-010 | no-validation | A preloaded face whose file is absent from disk | the href is still listed; no error is raised |

