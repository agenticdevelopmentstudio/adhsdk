
Tests live in `ThemeTypographyTests` (Swift Testing suite `ThemeTypography`): `systemHasAllRoles`, `sizeScaleApplies`, `explicitStyleWins`, `codableRoundTrip`, `colorThemeCarriesTypography` and `clampNonFinite`. `clampNonFinite` also asserts `clampedSizeScale(9)` is 4 and `(0.1)` is 0.5. The suite has no test of `sizeScaleRange` itself; that vector and the in-range clamp rows derive from the source and from the call sites in `ThemeStore` and `SemanticPalette`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| typography-001 | default-covers-roles, system-constant | `ThemeTypography.system.style(role).size` for each `TextRole.allCases` (test `systemHasAllRoles`) | every size greater than 0 |
| typography-002 | default-style-table | `ThemeTypography.system.style(.code).monospaced` and `.style(.body).monospaced` (test `systemHasAllRoles`) | true and false |
| typography-003 | default-style-table | `system.style(.title).size` versus `system.style(.body).size` (test `systemHasAllRoles`) | 22 is greater than 13 |
| typography-004 | default-style-table | `defaultStyle(.heading)`, `.caption`, `.button` | (15, semibold), (11, regular), (13, medium), `family` nil, `monospaced` false |
| typography-005 | size-effective, size-stored-unchanged | system typography with `sizeScale = 1.5`; read `size(.body)` and `style(.body).size` (test `sizeScaleApplies`) | 19.5 and 13 |
| typography-006 | style-lookup-override, style-lookup-default | set `styles["body"]` to `FontStyle(family: "Menlo", size: 17, weight: .bold, monospaced: true)` (test `explicitStyleWins`) | `style(.body)` has family `Menlo`, size 17, weight `.bold`; `style(.title).size` is 22 |
| typography-007 | style-lookup-no-mutation | call `style(.body)` on `ThemeTypography()` | `styles` is still empty |
| typography-008 | style-lookup-whole-entry | `styles["body"] = FontStyle(size: 20)`; read `style(.body)` | size 20, weight `.regular`, `monospaced` false, family nil; role default is not merged |
| typography-009 | codable-synthesized, styles-key, typography-conformances | `ThemeTypography(sizeScale: 1.25)` with `styles["title"] = FontStyle(family: "Avenir Next", size: 24, weight: .heavy)`; encode then decode (test `codableRoundTrip`) | decoded equals the original and `size(.title)` is 30 |
| typography-010 | typography-init-defaults, system-constant | `ThemeTypography()` and `ThemeTypography.system` | equal; `sizeScale` 1.0, `styles` empty |
| typography-011 | style-init-defaults | `FontStyle(size: 14)` | family nil, size 14, weight `.regular`, `monospaced` false |
| typography-012 | scale-range | `ThemeTypography.sizeScaleRange` | lower bound 0.5, upper bound 4 |
| typography-013 | clamp-function | `clampedSizeScale(0)`, `(0.1)`, `(0.5)`, `(1.0667)`, `(4)`, `(9)` | 0.5, 0.5, 0.5, 1.0667, 4, 4 |
| typography-014 | clamp-infinity | `clampedSizeScale(-.infinity)` and `(.infinity)` (test `clampNonFinite`) | 1.0 and 1.0 |
| typography-015 | clamp-callers, clamp-repair-not-refuse | `ThemeStore.importJSON` of a theme file declaring `"sizeScale": 0` with a valid palette | the imported theme's `typography.sizeScale` is 0.5; no error |
| typography-016 | clamp-callers | `SemanticPalette.scaled(by: 100)` | behaves as `scaled(by: 4)` |
| typography-017 | typography-init-no-clamp, size-uses-stored-scale | `ThemeTypography(sizeScale: 0).size(.body)` | 0 |
| typography-018 | decode-strict | decode `{"sizeScale": 1, "styles": {"body": {"size": 13, "weight": "plush", "monospaced": false}}}` | throws a decoding error; no default weight is substituted |
| typography-019 | decode-strict | decode `{"sizeScale": 1}` | throws `keyNotFound` for `styles` |
| typography-020 | role-cases, role-raw-value | `TextRole.allCases.map(\.rawValue)` | `["title", "heading", "body", "caption", "code", "button"]` |
| typography-021 | weight-cases | `FontWeight.allCases.count` and first and last case | 9; `ultraLight` and `black` |
| typography-022 | clamp-nan | `clampedSizeScale(.nan)`, `(.infinity)`, `(-.infinity)` | 1.0 for each |
| typography-023 | styles-unknown-key | `styles["footnote"] = FontStyle(size: 9)`; read every role | every role resolves as before; the unknown key is kept and not read |
| typography-024 | style-no-size-validation | `FontStyle(size: -3).size` and `ThemeTypography(styles: ["body": FontStyle(size: 0)]).size(.body)` | -3 and 0 |

