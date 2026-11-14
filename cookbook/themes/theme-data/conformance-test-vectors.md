
No test sits beside `theme-data.ts` or the generator. The tests that read the data go through the manifest: `rescued-themes.test.ts`, `darkAlwaysThemes.test.ts` and `buildScopedCss.test.ts` (`ThemeStyle.test.tsx` mocks the manifest and so never reads the data). Vectors 001 and 002 derive from them and the rest from the generator source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-data-001 | one-export-per-sheet, manifest-is-consumer | `rescued-themes.test.ts` "resolves in the themes record with non-empty css": `themes['crt-monitor']` and `themes['handheld-communicator']` | each entry's `css` is a string with length greater than 0, and its `id` equals the key |
| theme-data-002 | export-value-type, css-otherwise-verbatim | `darkAlwaysThemes.test.ts` "pins every token the light sheet sets": `themes.fishlamp.css` and `themes.charcoal.css` parsed as CSS | the string parses as stylesheet text, with a rule whose selector list contains `html:root` and `html:root[data-color-mode]:not(.dark)` |
| theme-data-003 | export-name, export-order | files `adh-comic.css`, `adh.css`, `dev-team.css`, `terminal-split.css` | exports `adhComicCss`, `adhCss`, `devTeamCss`, `terminalSplitCss`, in that order |
| theme-data-004 | relative-import-inlined, shared-palette-copied | `fishlamp.css` containing a relative `@import` of `fishlamp-palette.css` | `fishlampCss` holds the full palette text and no `@import './'`; `fishlampPaletteCss` is also exported |
| theme-data-005 | remote-import-kept | `dracula.css` beginning with a Google Fonts `@import url(...)` | `draculaCss` still contains that `@import url(...)` unchanged |
| theme-data-006 | self-import-error | a stylesheet containing `@import './self.css';` in a file named `self.css` | the script throws `inline-imports: <path> imports itself` and writes no output |
| theme-data-007 | missing-import-target, overwrite-output | `a.css` imports `./gone.css`, which does not exist; an older `theme-data.ts` is present | the script fails with a file-not-found error and the older file is untouched |
| theme-data-008 | completion-message | run with one `.css` file, then with two | prints `build-theme-data: 1 theme → src/theme-data.ts`, then `build-theme-data: 2 themes → src/theme-data.ts` |
| theme-data-009 | deterministic-output | run the script twice with no CSS change | the two output files are byte-identical |
| theme-data-010 | export-value-type, non-ascii-preserved | a sheet whose comment holds a double quote, a newline and an em dash | the export is one JSON string with `\"` and `\n` escaped and the em dash unescaped |
| theme-data-011 | generated-header, trailing-newline | any run | line 1 is the generated comment, line 2 is empty, and the file ends with exactly one newline |
| theme-data-012 | non-theme-sheets, no-other-source-consumer | the shipped `src/styles` directory | exports include `accessibilityCss`, `colorModeLightCss`, `fishlampPaletteCss` and `mikefullertonLandingCss`, and none of them is imported by the manifest |
| theme-data-013 | self-hosted-fonts-kept | the shipped `adh.css` with `@font-face` blocks | `adhCss` still contains its `@font-face` declarations |

