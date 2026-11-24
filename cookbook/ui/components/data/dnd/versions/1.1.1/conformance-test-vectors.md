
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dnd-001 | sortable-model-input | SortableSurface with zones array containing two zones, each with two items | Surface renders without error; zones are droppable |
| dnd-002 | drop-position-report | Zone contains items `[a, b, c]` in order; drag item `a` and drop it directly below `b` | onDrop callback receives `{ itemId: "a", fromZoneId, toZoneId, afterId: "b", beforeId: "c" }` |
| dnd-003 | no-op-reorder-ignored | Drag item in same zone and drop it in its original position | onDrop callback is NOT invoked |
| dnd-004 | pointer-drag-activation-distance | Pointer moves 3px from start; then moves 6px from start | Drag does not start at 3px; drag starts and active state is set at 6px+ |
| dnd-005 | continuous-drop-target-remeasurement | Start drag; zone grows in height mid-drag; drop item | Drop calculation uses the updated zone rect, not the original |
| dnd-006 | pointer-and-keyboard-interaction | Focus on SortableItem's grip; press Space or Enter to start; press Arrow Up/Down to move; press Enter to drop | Drag starts, item moves, drag completes and onDrop is called |
| dnd-007 | optional-drag-overlay | SortableSurface with renderOverlay prop provided | DragOverlay renders the result of renderOverlay(itemId) under pointer during drag |
| dnd-008 | optional-drag-overlay | SortableSurface without renderOverlay prop | No DragOverlay appears during drag |
| dnd-009 | axis-constraint | DragSurface with axis="x" | Dragging vertically has no effect; only horizontal movement is possible |
| dnd-010 | axis-constraint | DragSurface with axis="y" | Dragging horizontally has no effect; only vertical movement is possible |
| dnd-011 | drag-event-announcements | Focus on grip and start drag via keyboard; listen to screen reader announcements | Announcement includes "Picked up {itemName}" |
| dnd-012 | optional-item-and-zone-descriptions | SortableSurface with describeItem={(id) => `Card ${id}`} and describeZone={(id) => `Column ${id}`} | Announcements use "Card X" and "Column Y" instead of bare IDs |
| dnd-013 | nearest-corner-collision-detection | Two zones side by side; dragged item's nearest corner sits 10px from Zone A's near edge and 40px from Zone B's near edge | Item lands in Zone A — the zone whose corner is closest — not by center point or bounding-box overlap |
| dnd-014 | dragged-item-de-emphasis | Start pointer drag in SortableSurface; inspect element style during drag | `opacity: 0.4` is applied to the dragged item's element |
| dnd-015 | dragged-item-visual-elevation | Start pointer drag in DragSurface; inspect element style during drag | `zIndex: 20` and `position: relative` are applied |
| dnd-016 | grip-touch-scroll-suppression | On touch device, attempt to scroll by dragging on a DragGrip | Pointer sensor receives the move events; browser does not consume scroll |
| dnd-017 | horizontal-layout-support, center-crossing-drop-position | orientation="horizontal"; dragged item's translated rect center at x=150; target item's rect spans x=100–180 (center x=140) | Dragged center (150) has passed the target's center (140) → item lands AFTER the target |
| dnd-018 | conditional-drag-disabling | SortableItem with enabled={false} | Item cannot be picked up; pointer and keyboard sensors are inactive for this item |
| dnd-019 | conditional-keyboard-attribute-spreading | SortableItem with keyboard={false} | Only listeners are spread on handleProps; no `role`, `tabIndex`, or attributes are included |
| dnd-020 | sortable-zone-droppable | SortableZone with empty itemIds array | Zone's own droppable is reachable; dropping into it lands item at the end of that (empty) zone |
| dnd-021 | drag-surface-drop-payload | Drag item in DragSurface 15px right and 3px down; release over a target | onDrop callback receives `{ itemId, targetId: <target id>, delta: { x: 15, y: 3 } }` |
| dnd-022 | drag-surface-config-input | DragSurface rendered with onDrop, describeItem, describeTarget, renderOverlay, axis, and keyboard all provided | Surface renders without error; describeItem/describeTarget values are used in announcements |

