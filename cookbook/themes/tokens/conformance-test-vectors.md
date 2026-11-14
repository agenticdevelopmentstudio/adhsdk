
No test sits beside `tokens.ts`. The themes package tests (`appearanceScope.test.ts`, `AppearanceScope.test.tsx`, `buildScopedCss.test.ts`, `clearAppearance.test.ts`, `darkAlwaysThemes.test.ts`, `DocumentLoadScript.test.tsx`, `rescued-themes.test.ts`, `ThemeStyle.test.tsx`) do not target these functions, so the vectors below are derived from the regular expressions in the source and are the tests a port should write.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tokens-001 | imports-pattern, imports-href, imports-removed | `splitImports('@import url("a.css");body{}')` | `imports` is `["a.css"]`; `rest` is `body{}` |
| tokens-002 | imports-pattern, imports-removed | `splitImports("@import url( 'b.css' ) ;x")` | `imports` is `["b.css"]`; `rest` is `x` |
| tokens-003 | imports-pattern, imports-href | `splitImports("@import url(c.css)x")` (unquoted, no semicolon) | `imports` is `["c.css"]`; `rest` is `x` |
| tokens-004 | imports-order, imports-removed | `splitImports('@import url(a.css);p{}@import url(b.css);q{}')` | `imports` is `["a.css", "b.css"]`; `rest` is `p{}q{}` |
| tokens-005 | imports-order | `splitImports('@import url(a.css);@import url(a.css);')` | `imports` is `["a.css", "a.css"]`; `rest` is the empty string |
| tokens-006 | imports-url-only, imports-none | `splitImports('@import "d.css";p{}')` | `imports` is `[]`; `rest` equals the input |
| tokens-007 | imports-none, no-throw | `splitImports("")` | `imports` is `[]`; `rest` is `""` |
| tokens-008 | imports-everywhere | `splitImports('/* @import url(e.css); */p{}')` | `imports` is `["e.css"]`; `rest` is `/*  */p{}` |
| tokens-009 | prop-pattern, prop-name-verbatim, prop-value-trimmed | `parseRootProps(":root{--a:1; --B : two words ;}")` | Map with `--a` to `1` and `--B` to `two words`, in that order |
| tokens-010 | root-missing, no-throw | `parseRootProps("body{--a:1;}")` and `parseRootProps("")` | Both return an empty Map |
| tokens-011 | root-block-first | `parseRootProps(":root{--a:1;} :root{--b:2;}")` | Map has only `--a` |
| tokens-012 | prop-semicolon-required | `parseRootProps(":root{--a:1;--b:2}")` | Map has only `--a` |
| tokens-013 | prop-duplicates, prop-ordered | `parseRootProps(":root{--a:1;--b:2;--a:3;}")` | Entries in order `--a` to `3`, `--b` to `2` |
| tokens-014 | prop-value-ends-at-semicolon | `parseRootProps(":root{--i:url(data:image/png;base64,AA);}")` | `--i` maps to `url(data:image/png` |
| tokens-015 | prop-empty-value-kept | `parseRootProps(":root{--a: ;}")` | Map has `--a` to the empty string |
| tokens-016 | non-custom-ignored | `parseRootProps(":root{color:red;--a:1;}")` | Map has only `--a` |
| tokens-017 | root-block-ends-at-brace | `parseRootProps(":root{--a:1;} p{--b:2;}")` | Map has only `--a` |
| tokens-018 | root-block-anywhere | `parseRootProps("html:root{--a:1;}")` | Map has `--a` to `1` |
| tokens-019 | comments-not-parsed | `parseRootProps(":root{/* --a:1; */--b:2;}")` | Map has `--a` to `1` and `--b` to `2` |
| tokens-020 | prop-pattern | `parseRootProps(":root{--é:1;--a_b-c:2;}")` | Map has only `--a_b-c` to `2`; the non-ASCII name is not matched |
| tokens-021 | no-shared-state, pure | Call `splitImports` twice on the same string containing an import | Both calls return equal results |

