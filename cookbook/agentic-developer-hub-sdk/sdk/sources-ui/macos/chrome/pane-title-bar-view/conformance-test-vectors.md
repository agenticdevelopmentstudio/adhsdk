
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-title-bar-001 | render-title-label | Initialize component; set title to "My File.txt" | Title label displays "My File.txt" |
| pane-title-bar-002 | sync-tooltip-with-title | Set title to "Long File Name"; then set title to "" | Tooltip equals "Long File Name" after first set; tooltip is nil after second set |
| pane-title-bar-003 | render-fixed-height | Initialize component; read height | Height is exactly 26pt |
| pane-title-bar-004 | truncate-title-in-middle | Set title to "VeryLongFileName.extension"; constrain pane width to 80pt | Title text truncates in middle (e.g., "VeryLong...extension") not "VeryLongFile..." |
| pane-title-bar-005 | support-accessory-views | Set accessoryViews to [viewA, viewB] | Both views appear in accessory stack in order |
| pane-title-bar-006 | replace-accessory-views-atomically | Set accessoryViews to [viewA]; then set to [viewC, viewD] | viewA is removed from view tree; viewC and viewD appear in order; no views are orphaned |
| pane-title-bar-007 | support-optional-gear-view | Initialize component; gearView is nil by default | Gear area is empty; accessory stack extends to trailing margin |
| pane-title-bar-008 | support-optional-gear-view, gear-trailing | Set gearView to a button; set accessoryViews to [viewA] | Gear button appears at trailing edge; viewA appears to its left with 6pt gap |
| pane-title-bar-009 | center-content-vertically | Initialize component; inspect layout | Title label centerY equals bar centerY; accessory stack centerY equals bar centerY; gear centerY equals bar centerY |
| pane-title-bar-010 | honor-yield-width-request | Call yieldWidthToContainer(); then constrain the bar's width to 0pt and lay out | Layout resolves with no unsatisfiable-constraint conflict; the bar renders at 0pt width because every subview's horizontal compression resistance is priority 1 |
| pane-title-bar-011 | apply-yield-to-future-subviews | Call yieldWidthToContainer(); then set gearView; inspect gear constraint | Gear has compression resistance priority 1 (minimum) for horizontal axis |
| pane-title-bar-012 | accessory-spacing | Set accessoryViews to [viewA, viewB]; inspect stack spacing | Spacing between viewA and viewB is 4pt |
| pane-title-bar-013 | support-optional-gear-view | Initialize component; do not set gearView; inspect accessoryStack trailing constraint | accessoryStack's trailing anchor constant equals -6pt relative to the bar's trailing anchor |
| pane-title-bar-014 | bottom-separator | Initialize component; inspect hairline view constraints | Hairline view's leading and trailing anchors equal the bar's leading and trailing anchors; its bottom anchor equals the bar's bottom anchor |
| pane-title-bar-015 | leading-controls-cluster | Initialize component; inspect controls view constraints | controls.leadingAnchor equals bar.leadingAnchor + 6pt; controls.centerYAnchor equals bar.centerYAnchor |

