
The source ships no test that asserts the adjustments directly. Vectors native-001 and native-002 follow the assertions in `BuiltInThemesTests` (36 themes in `all`, unique ids) and `PortedThemeTests` (every ported theme is in `all`); the rest are derived from the source itself.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| native-001 | native-list, native-map | `BuiltInThemes.webPortedNative.map(\.id)` against `BuiltInThemes.webPorted.map(\.id)` | The two id arrays are equal, element by element (consistent with the `PortedThemeTests` membership and `BuiltInThemesTests` unique-id assertions) |
| native-002 | native-map | `BuiltInThemes.all.count` | 36, the hand-authored set plus `webPortedNative` (`BuiltInThemesTests`) |
| native-003 | dispatch-default | `nativeAdjusted` on the first `webPorted` theme whose id is not `BuiltInThemes.fishlamp.id` | The returned theme is equal to the input |
| native-004 | dispatch-fishlamp, fishlamp-selection | `nativeAdjusted(BuiltInThemes.fishlamp).selection.hexString` | `#232831FF` |
| native-005 | fishlamp-card, ember-shared | `nativeAdjusted(BuiltInThemes.fishlamp).roleOverrides[ThemeRole.card.rawValue]?.hexString` | `#17130FFF` |
| native-006 | fishlamp-selection-edge | `nativeAdjusted(BuiltInThemes.fishlamp).roleOverrides[ThemeRole.selectionEdge.rawValue]?.hexString` | `#E8A33DFF` |
| native-007 | fishlamp-pane-backdrop, fishlamp-project-replaced, ember-shared | `nativeAdjusted(BuiltInThemes.fishlamp).project` | `ThemeProjectOptions(paneBackdrop: #17130FFF)` with `highlightActivePane` and `paneOutline` nil |
| native-008 | fishlamp-overrides-merged | `nativeAdjusted(BuiltInThemes.fishlamp).roleOverrides[ThemeRole.chatSurface.rawValue]?.hexString` | `#17130FF0`, as generated |
| native-009 | fishlamp-untouched-fields | Compare `id`, `name`, `appearance`, `foreground`, `background`, `cursor`, `ansi` and `typography` of `nativeAdjusted(BuiltInThemes.fishlamp)` with `BuiltInThemes.fishlamp` | All equal |
| native-010 | input-preserved | Read `BuiltInThemes.fishlamp.selection.hexString` after calling `nativeAdjusted(BuiltInThemes.fishlamp)` | `#E8A33D4D`, the generated value |
| native-011 | dispatch-by-id | A copy of `BuiltInThemes.fishlamp` with `name` changed to "Other" | The Fishlamp adjustment is still applied (`selection` is `#232831FF`) |
| native-012 | dispatch-by-id, dispatch-default | A copy of `BuiltInThemes.fishlamp` with `id` changed to a new string | Returned unchanged; `selection` stays `#E8A33D4D` |
| native-013 | fishlamp-project-replaced | A copy of `BuiltInThemes.fishlamp` with `project` set to `ThemeProjectOptions(highlightActivePane: true)` | The adjusted `project` has `highlightActivePane` nil and `paneBackdrop` `#17130FFF` |
| native-014 | hex-literals | `RGBAColor(hexString: "#17130fff")`, `"#232831ff"`, `"#e8a33dff"` | Each returns non-nil |

