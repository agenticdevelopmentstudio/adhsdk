
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-strip-001 | fixed-width | View initialized with edge `.leading` | View width is 28 points |
| pane-strip-002 | restore-button | Default initialization | Restore button visible at top, displays plus symbol |
| pane-strip-003 | glyph-display | Default initialization with no symbolName override | Glyph displays `square.dashed` symbol |
| pane-strip-004 | symbol-name | Initialize with `symbolName: "folder"` | Glyph displays folder symbol |
| pane-strip-005 | glyph-tracks-symbol | After init, set `symbolName = "star"` | Glyph updates to star symbol immediately |
| pane-strip-006 | restore-callback | Set `onRestore` callback, tap restore button | Callback is invoked |
| pane-strip-007 | tooltip | Initialize with `tooltip: "Documents"` | Tooltip text "Documents" appears on glyph hover |
| pane-strip-008 | tooltip-tracks-property | After init, set `tooltip = "Settings"` | Tooltip updates to "Settings" immediately |
| pane-strip-009 | hairline-inward | Initialize with edge `.leading` | Hairline positioned at trailing side (interior) |
| pane-strip-010 | hairline-inward | Initialize with edge `.trailing` | Hairline positioned at leading side (interior) |
| pane-strip-011 | glyph-fallback | Initialize with `symbolName: "nonexistent.symbol"` | Glyph displays `square.dashed` fallback |
| pane-strip-012 | accessibility-labels | Default initialization | Restore button has accessibility label "Restore Pane", accessibility ID `pane.restore` |
| pane-strip-013 | accessibility-labels | Initialize with `tooltip: "Mail"` | Glyph accessibility description is "Mail" |
| pane-strip-014 | theme-colors | Apply theme with secondary text color #666666 | Icon and button render in #666666 |
| pane-strip-015 | accessibility-labels | Initialize with `tooltip: ""` (default) | Glyph accessibility description is "Minimized Pane" |
| pane-strip-016 | restore-callback | `onRestore` left `nil` (default), tap restore button | No crash; tap has no observable effect (safe no-op) |
| pane-strip-017 | theme-colors | Apply theme with border color #444444 | Hairline renders in #444444 |
| pane-strip-018 | hairline-inward | Attempt to change `edge` after initialization | No API exists to mutate `edge`; hairline position stays fixed to the value passed at init |

