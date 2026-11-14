
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| color-theme-001 | codable-round-trip, color-encoding | Test `round-trips through Codable`: a built-in theme with `roleOverrides` set to accent `#11223344`, encoded then decoded | Decoded theme equals the original |
| color-theme-002 | codable-round-trip, identity-fields | Test `attribution and isImported round-trip through Codable`: a theme with `isImported = true` and `attribution = "Arctic Ice Studio"` | Decoded theme equals the original; `isImported` is true; `attribution` is "Arctic Ice Studio" |
| color-theme-003 | decode-lock-flags-default | Test `a shared/hand-authored theme JSON that omits isBuiltIn still decodes`: JSON with no `isBuiltIn`, `isImported`, `roleOverrides` or `typography` keys and 16 ANSI colors | Decodes; `isBuiltIn` false; `isImported` false |
| color-theme-004 | decode-attribution-default, decode-lock-flags-default | Test `themes persisted before isImported/attribution existed still decode`: JSON with `isBuiltIn:false` and no `isImported` or `attribution` | `isImported` false; `attribution` nil |
| color-theme-005 | is-editable, is-locked, is-deletable | Test `editability`: a built-in; the same theme with `isImported = true` and `isBuiltIn = false`; the same with both false | Built-in: locked, not editable, not deletable. Imported: locked, not editable, deletable. Custom: editable, not locked, deletable |
| color-theme-006 | ansi-color-lookup | Test `ansiColor(at:) returns the color in range and nil out of range`: indexes 0, 15, 16, -1 on a built-in | `ansi[0]`, `ansi[15]`, nil, nil |
| color-theme-007 | has-valid-palette, ansi-color-count, init-no-validation | Test `hasValidPalette requires exactly 16 ANSI colors`: a built-in, and a theme constructed with 3 ANSI colors | Built-in true; the 3-color theme constructs and reports false |
| color-theme-008 | color-encoding | Test `RGBAColor clamps out-of-range and non-finite components to [0, 1]`: components 1.5, -0.2, 2.0, 9 and NaN, 0.5, +infinity, -infinity | 1, 0, 1, 1 and 0, 0.5, 1, 0 |
| color-theme-009 | decode-required-keys | JSON with every key except `ansi` | Decoding throws |
| color-theme-010 | decode-role-overrides-default, decode-typography-default, decode-feature-options-absent | The JSON from color-theme-003 | `roleOverrides` is empty; `typography == .system`; `terminal` and `project` are nil |
| color-theme-011 | init-defaults, init-required | Initializer with only the required arguments, called twice | Both `id` values are UUID strings and differ; `isBuiltIn`, `isImported` false; `attribution` nil; `roleOverrides` empty |
| color-theme-012 | appearance-cases, appearance-identifier | `ThemeAppearance.allCases` and `.auto.id` | Three cases `dark`, `light`, `auto`; id "auto" |
| color-theme-013 | decode-no-palette-validation | JSON with 3 ANSI colors | Decodes; `hasValidPalette` is false |
| color-theme-014 | color-encoding | JSON whose `foreground` is "not-a-color" | Decoding throws a data-corrupted error |

