
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-manifest-001 | theme-ids-derived, themes-record-total | `themeIds.length` | 39; each key of `themes` appears once. |
| theme-manifest-002 | theme-ids-derived, manifest-exports | `themeIds` checked for `crt-monitor` and `handheld-communicator` (`rescued-themes.test.ts`, "is a member of themeIds") | Both keys are present. |
| theme-manifest-003 | entry-id-matches-key, entry-css-nonempty | `themes['crt-monitor']` and `themes['handheld-communicator']` (`rescued-themes.test.ts`, "resolves in the themes record with non-empty css") | Entry is defined, `entry.id` equals the key, `entry.css` is a string longer than 0 characters. |
| theme-manifest-004 | themes-record-total, theme-ids-derived | For every key in `themeIds`, `buildScopedCss(themes[key].css, '.host')` (`buildScopedCss.test.ts`, "leaves no unrewritten root anchor in any shipped theme") | Every key resolves to an entry whose css the function can process; the test never meets an undefined entry. |
| theme-manifest-005 | entry-label-human | `themes['rose-pine'].label`, `themes.synthwave84.label`, `themes['adh-comic'].label` | `Rosé Pine`, `Synthwave '84`, `ADH · Comic`. |
| theme-manifest-006 | theme-ids-order | `themeIds[0]`, `themeIds[7]`, `themeIds[38]` | `adh`, `adh-manrope`, `handheld-communicator`. |
| theme-manifest-007 | unknown-key-lookup | `themes['no-such-theme']` read through an untyped cast | `undefined`; no throw. |
| theme-manifest-008 | entry-label-human | `themes['green-matrix-glass'].label` | `Green Matrix (Glass)`. |
| theme-manifest-009 | theme-ids-order | `themeIds.indexOf('gruvbox') - themeIds.indexOf('whimsical')` | 1; the order is declaration order, so `gruvbox` follows `whimsical` and does not sort before it. |
| theme-manifest-010 | css-source-generated, no-side-effects | Import the module in a node environment with no `document` | Import succeeds and all runtime exports (`themes`, `themeIds`) are defined. |

