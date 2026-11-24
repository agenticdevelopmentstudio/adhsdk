
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-manifest-001 | theme-ids-derived, themes-record-total | `themeIds.length` | equals the number of rows in the Registered themes table; each key of `themes` appears once. |
| theme-manifest-002 | theme-ids-derived, manifest-exports | `themeIds` checked for `crt-monitor` and `handheld-communicator` (`rescued-themes.test.ts`, "is a member of themeIds") | Both keys are present. |
| theme-manifest-003 | entry-id-matches-key, entry-css-nonempty | `themes['crt-monitor']` and `themes['handheld-communicator']` (`rescued-themes.test.ts`, "resolves in the themes record with non-empty css") | Entry is defined, `entry.id` equals the key, `entry.css` is a string longer than 0 characters. |
| theme-manifest-004 | themes-record-total, theme-ids-derived | For every key in `themeIds`, `buildScopedCss(themes[key].css, '.host')` (`buildScopedCss.test.ts`, "leaves no unrewritten root anchor in any shipped theme") | Every key resolves to an entry whose css the function can process; the test never meets an undefined entry. |
| theme-manifest-005 | entry-label-human | `themes['rose-pine'].label`, `themes.synthwave84.label`, `themes['adh-comic'].label` | `Rosé Pine`, `Synthwave '84`, `ADH · Comic`. |
| theme-manifest-006 | theme-ids-order | `themeIds[0]`, `themeIds[7]`, `themeIds.at(-1)` | `adh`, `adh-manrope`, `handheld-communicator`. |
| theme-manifest-007 | unknown-key-lookup | `themes['no-such-theme']` read through an untyped cast | `undefined`; no throw. |
| theme-manifest-008 | entry-label-human | `themes['green-matrix-glass'].label` | `Green Matrix (Glass)`. |
| theme-manifest-009 | theme-ids-order | `themeIds.indexOf('gruvbox') - themeIds.indexOf('whimsical')` | 1; the order is declaration order, so `gruvbox` follows `whimsical` and does not sort before it. |
| theme-manifest-010 | css-source-generated, no-side-effects | Import the module in a node environment with no `document` | Import succeeds and all runtime exports (`themes`, `themeIds`) are defined. |
| theme-manifest-011 | entry-id-matches-key, entry-css-nonempty | For every `k` in `themeIds`, read `themes[k]` | `themes[k].id === k` and `themes[k].css.length > 0`. |
| theme-manifest-012 | theme-key-union | `expectTypeOf<ThemeKey>()` compared with the keys of the Registered themes table | the union is exactly those literals. |
| theme-manifest-013 | theme-entry-shape | `expectTypeOf<ThemeEntry>()` | has `id: ThemeKey`, `label: string` and `css: string`. |
| theme-manifest-014 | theme-ids-computed-once | Add a key to `themes` at run time through a cast, then read `themeIds` | `themeIds` is unchanged. |
| theme-manifest-015 | no-ordering-rules | Inspect the module's exports | no default theme, grouping or sort is exported. |
