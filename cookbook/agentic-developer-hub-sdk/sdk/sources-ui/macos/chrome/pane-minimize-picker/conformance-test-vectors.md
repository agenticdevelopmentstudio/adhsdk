
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-minimize-001 | render-four-arrows | Initialize PaneMinimizeCrossView with any available edges set | Grid contains exactly four buttons at top, leading, trailing, and bottom positions. |
| pane-minimize-002 | initialize-with-available-edges | Initialize with availableEdges = {.top, .leading} | Top and leading buttons are enabled; trailing and bottom buttons are disabled. |
| pane-minimize-003 | disable-unavailable-arrows | Initialize with availableEdges = {} | All four buttons are disabled. |
| pane-minimize-004 | invoke-callback-on-selection | availableEdges = {.top}; user taps top arrow | onPick callback is called with .top. |
| pane-minimize-005 | close-popover-before-callback | Picker is shown (isShown == true); user taps an available arrow | onPick's closure observes isShown == false at the moment it is called — the popover has already closed before onPick runs. |
| pane-minimize-006 | support-dynamic-availability | Initialize with {.top}; set availableEdges = {.top, .leading} | Leading button transitions from disabled to enabled; tint color updates immediately. |
| pane-minimize-007 | apply-theme-tint | Initialize with availableEdges = {.top, .leading}; inspect contentTintColor of all four buttons | Top and leading buttons' contentTintColor equals the theme's primaryText color; bottom and trailing buttons' contentTintColor equals the theme's tertiaryText color. |
| pane-minimize-008 | display-tooltips | Hover over any arrow button | Tooltip appears with the edge's display name. |

