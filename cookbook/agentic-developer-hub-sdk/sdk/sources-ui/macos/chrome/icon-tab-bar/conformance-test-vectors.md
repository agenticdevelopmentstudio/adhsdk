
No test file exists beside the source (a search of the repo found none naming `IconTabBar`), so these vectors are derived from the source's behaviour.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| icon-tab-bar-001 | one-segment-per-item | Three items created in the order a, b, c | Control has three segments in that order |
| icon-tab-bar-002 | one-segment-per-item | An empty item list | Control has no segments; no crash |
| icon-tab-bar-003 | symbol-image, tooltip-title | Item with symbol `folder` and title `Projects` | Segment image is the `folder` symbol with accessibility description `Projects`; tooltip is `Projects` |
| icon-tab-bar-004 | missing-symbol-blank | Item whose symbol names no system symbol | Segment is drawn with an empty image; creation succeeds |
| icon-tab-bar-005 | segment-width, equal-distribution | Any item list | Each segment width is 32 and widths are equal |
| icon-tab-bar-006 | hug-icons | Bar placed in a container much wider than its icons | Bar stays its icon width; it does not stretch |
| icon-tab-bar-007 | selected-id-display, select-one-tracking | Set `selectedID` to the second item's id | Second segment selected; no other segment selected |
| icon-tab-bar-008 | selected-id-none | Set `selectedID` to an id no item has | No segment selected |
| icon-tab-bar-009 | selected-id-none | Set `selectedID` to `nil` after an item was selected | No segment selected |
| icon-tab-bar-010 | selected-id-unchanged | Set `selectedID` to the value it already holds | Selection is not redrawn |
| icon-tab-bar-011 | report-click | Click the third segment | `onSelect` is called once with the third item's id |
| icon-tab-bar-012 | caller-owns-choice | `selectedID` is the first item's id; click the second segment; caller does not update `selectedID` | `onSelect` receives the second id; first segment is drawn selected again |
| icon-tab-bar-013 | caller-owns-choice | As above, but caller sets `selectedID` to the second id inside `onSelect` | Second segment ends up selected |
| icon-tab-bar-014 | ignore-out-of-range | Control reports selected segment -1 or one beyond the last | `onSelect` is not called |
| icon-tab-bar-015 | report-click | `onSelect` is `nil`; click a segment | No crash; selection is redrawn from `selectedID` |
| icon-tab-bar-016 | no-keyboard-capture | Click a segment while a text field holds the keyboard | The text field keeps the keyboard; no focus ring appears |
| icon-tab-bar-017 | accessibility-identifier | Created with `project-shelf.panels` | Control's accessibility identifier is `project-shelf.panels` |
| icon-tab-bar-018 | theme-track-appearance | Palette window background with brightness 0.2 while the system is in light appearance | Control appearance is the dark one |
| icon-tab-bar-019 | theme-track-appearance | Palette window background with brightness 0.9 while the system is in dark appearance | Control appearance is the light one |
| icon-tab-bar-020 | theme-accent-selection, theme-initial-apply | Create the bar under a theme whose accent is a known colour | Selected segment bezel colour equals the palette's accent, with no change of theme needed |
| icon-tab-bar-021 | theme-follow-changes | Switch the active theme from a light one to a dark one | Track appearance and selection colour update to the new palette |
| icon-tab-bar-022 | no-coder-init | Decode the view from an archive | The unavailable initialiser traps with `init(coder:) is not supported` |
| icon-tab-bar-023 | main-actor | Use the bar from a background thread | Not permitted; the type is main-actor isolated and the compiler refuses |

