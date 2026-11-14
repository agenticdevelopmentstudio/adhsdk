
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-001 | active-theme, mark-active-selection | `activeThemeId="sepia"` with the built-in registry (`dark`, `light`, `sepia`, `github`) | The control's selected value is `"sepia"` |
| theme-002 | mark-active-selection | Component re-rendered with `activeThemeId` changed from `"light"` to `"github"` | The control's selected value changes to `"github"`, displaying the label "GitHub" |
| theme-003 | emit-theme-change | User selects a different theme from the control | The change callback is invoked once with the selected theme's id string |
| theme-004 | render-theme-options | Built-in registry: `{id: "dark", label: "Dark"}`, `{id: "light", label: "Light"}`, `{id: "sepia", label: "Sepia"}`, `{id: "github", label: "GitHub"}` | Four options render, in that order, each with the matching id as its value and the matching label as its visible text |
| theme-005 | unique-control-id | Two instances of the component render on the same page | Each instance's label and selection control share a distinct identifier pair; no duplicate `id` attribute appears in the DOM |
| theme-006 | label-control | Component renders | A label element is present and programmatically associated with the selection control via its unique identifier |
| theme-007 | accessible-label | Component renders | The selection control exposes the accessible name "Select reading theme" |
| theme-008 | group-container | Component renders | The label and selection control are wrapped in a single container exposing a group role |
| theme-009 | mark-active-selection, emit-theme-change | User selects the theme that is already active (a native `<select>` fires no change event) | The control's selected value is unchanged; the change callback is not invoked |
| theme-010 | render-theme-options | The `../themes/registry` module is mocked so `VIEWER_THEMES` is empty | The control renders with no options; no error is thrown |
| theme-011 | active-theme | `activeThemeId="not-a-theme"` with the built-in registry | The browser shows the first option (`Dark`) as the visible selection; picking `light` invokes the change callback with `"light"`, and picking `Dark` invokes nothing |

