
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| options-001 | accept-custom-rows | Initialize with `rows: [sliderView, popupView, textFieldView]` | All three row views are rendered in the dialog in vertical order. |
| options-002 | render-content-in-vertical-stack | Initialize with heading, 2 rows, Done button | Stack is vertical; heading renders above rows; rows render above Done button; spacing and alignment are consistent. |
| options-003 | support-dynamic-heading | Initialize with `heading: "Settings"`, then set `heading = nil` | Heading label is hidden; layout recalculates without heading space. |
| options-004 | support-dynamic-heading | Set heading to a new string after initialization | Heading label updates immediately to show the new text; dialog layout remains stable. |
| options-005 | provide-done-callback | Initialize with `onDone` callback, press Done button | `onDone` callback fires exactly once. |
| options-006 | provide-close-callback | Initialize with `onDidClose` callback, present dialog, then dismiss | `onDidClose` fires after dialog is off-screen. |
| options-007 | set-return-key-equivalent | Initialize with focus in a row control (not the Done button), press Return | Done button's action fires via its key equivalent rather than direct focus; `onDone` fires. |
| options-008 | no-change-buffering | Add a slider row that triggers an action on value change, interact with slider | Row action fires immediately; no commit or cancel operation occurs. |
| options-009 | support-accessibility-identification | Initialize with `accessibilityPrefix: "prefs"` | Dialog container has accessibility ID `"prefs.dialog"`; Done button has ID `"prefs.dialog.done"`. |
| options-010 | respect-row-width-constraint | Add a row with a long label and trailing button | Row is sized to full dialog width minus insets; content does not exceed dialog width. |
| options-011 | use-minimum-width-floor | Add a row wider than 340pt (e.g., a popup with a long provider name) | Dialog expands to accommodate the row; minimum width is not restrictive. |
| options-012 | support-accessibility-identification | Initialize with default accessibility prefix | Done button accessibility ID is `"options.dialog.done"`. |
| options-013 | render-content-in-vertical-stack | Initialize with `rows: []` and a heading | Dialog renders the heading and the Done button only; no row spacing is applied. |
| options-014 | support-dynamic-heading | Initialize with `heading: "Settings"`, set `heading = nil`, then set `heading = "Settings"` again | Heading label re-appears with its original text; layout recalculates to include heading space again. |
| options-015 | provide-close-callback | Initialize with `onDidClose` callback, present and dismiss the dialog exactly once | `onDidClose` fires exactly once. |
| options-016 | use-minimum-width-floor | Initialize with rows no wider than the default and no explicit `width` | Dialog width equals 340pt, the default floor. |

