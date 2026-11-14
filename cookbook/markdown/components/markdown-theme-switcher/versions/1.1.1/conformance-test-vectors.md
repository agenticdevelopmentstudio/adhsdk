
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-001 | active-theme, mark-active-selection | `activeThemeId="dark"` with three themes in the registry (`light`, `dark`, `high-contrast`) | The control's selected value is `"dark"` |
| theme-002 | mark-active-selection | Component re-rendered with `activeThemeId` changed from `"light"` to `"high-contrast"` | The control's selected value changes to `"high-contrast"`, displaying the label "High Contrast" |
| theme-003 | emit-theme-change | User selects a different theme from the control | The change callback is invoked once with the selected theme's id string |
| theme-004 | render-theme-options | Registry contains `{id: "light", label: "Light"}`, `{id: "dark", label: "Dark"}`, `{id: "high-contrast", label: "High Contrast"}` | Three options render, each with the matching id as its value and the matching label as its visible text |
| theme-005 | unique-control-id | Two instances of the component render on the same page | Each instance's label and selection control share a distinct identifier pair; no duplicate `id` attribute appears in the DOM |
| theme-006 | label-control | Component renders | A label element is present and programmatically associated with the selection control via its unique identifier |
| theme-007 | accessible-label | Component renders | The selection control exposes the accessible name "Select reading theme" |
| theme-008 | group-container | Component renders | The label and selection control are wrapped in a single container exposing a group role |
| theme-009 | mark-active-selection, emit-theme-change | User selects the theme that is already active | The control's selected value is unchanged; the change callback still fires with that theme's id |
| theme-010 | render-theme-options | Registry is empty | The control renders with no options; no error is thrown |
| theme-011 | active-theme | `activeThemeId` does not match any theme id in the registry | The control renders with no option visibly selected; selecting any option still invokes the change callback |

