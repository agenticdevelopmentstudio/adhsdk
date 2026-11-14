
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dnd-001 | sortable-model-input | SortableSurface with zones array containing two zones, each with two items | Surface renders without error; zones are droppable |
| dnd-002 | drop-position-report | Zone contains items `[a, b, c]` in order; drag item `a` and drop it directly below `b` | onDrop callback receives `{ itemId: "a", fromZoneId, toZoneId, afterId: "b", beforeId: "c" }` |
| dnd-003 | no-op-reorder-ignored | Drag item in same zone and drop it in its original position | onDrop callback is NOT invoked |
| dnd-004 | pointer-drag-activation-distance | Pointer moves 3px from start; then moves 6px from start | Drag does not start at 3px; drag starts and active state is set at 6px+ |
| dnd-005 | continuous-drop-target-remeasurement | Start drag; zone grows in height mid-drag; drop item | A drop released inside the newly grown area (for example, a zone that grew from 100px to 300px tall, released at 250px from its top) lands in that zone, at the position that point implies |
| dnd-006 | pointer-and-keyboard-interaction | Focus on SortableItem's grip; press Space or Enter to start; press Arrow Up/Down to move; press Enter to drop | Drag starts, item moves, drag completes and onDrop is called |
| dnd-007 | optional-drag-overlay | SortableSurface with renderOverlay prop provided | DragOverlay renders the result of renderOverlay(itemId) under pointer during drag |
| dnd-008 | optional-drag-overlay | SortableSurface without renderOverlay prop | No DragOverlay appears during drag |
| dnd-009 | axis-constraint | DragSurface with axis="x" | Dragging vertically has no effect; only horizontal movement is possible |
| dnd-010 | axis-constraint | DragSurface with axis="y" | Dragging horizontally has no effect; only vertical movement is possible |
| dnd-011 | drag-event-announcements | Focus on grip and start drag via keyboard; listen to screen reader announcements | Announcement includes "Picked up {itemName}" |
| dnd-012 | optional-item-and-zone-descriptions | SortableSurface with describeItem={(id) => `Card ${id}`} and describeZone={(id) => `Column ${id}`} | Announcements use "Card X" and "Column Y" instead of bare IDs |
| dnd-013 | nearest-corner-collision-detection | Zone A spans x 0–100, y 0–200; Zone B spans x 140–240, y 0–200; the dragged item is 40×40 with corners at x 90–130, y 80–120 | Item lands in Zone A — the zone whose four corners are closest to the item's four corners (summed distance about 412 against about 461 for Zone B) — not by center point or bounding-box overlap |
| dnd-014 | dragged-item-de-emphasis | Start pointer drag in SortableSurface; inspect element style during drag | `opacity: 0.4` is applied to the dragged item's element |
| dnd-015 | dragged-item-visual-elevation | Start pointer drag in DragSurface; inspect element style during drag | `zIndex: 20` and `position: relative` are applied |
| dnd-016 | grip-touch-scroll-suppression | Render a DragGrip and read its computed `touch-action` | `touch-action` is `none`, so the browser does not claim a touch gesture for scrolling |
| dnd-017 | horizontal-layout-support, center-crossing-drop-position | orientation="horizontal"; dragged item's translated rect center at x=150; target item's rect spans x=100–180 (center x=140) | Dragged center (150) has passed the target's center (140) → item lands AFTER the target |
| dnd-018 | conditional-drag-disabling | SortableItem with enabled={false} | Item cannot be picked up; pointer and keyboard sensors are inactive for this item |
| dnd-019 | conditional-keyboard-attribute-spreading | SortableItem with keyboard={false} | Only listeners are spread on handleProps; no `role`, `tabIndex`, or attributes are included |
| dnd-020 | sortable-zone-droppable | SortableZone with empty itemIds array | Zone's own droppable is reachable; dropping into it lands item at the end of that (empty) zone |
| dnd-021 | drag-surface-drop-payload | Drag item in DragSurface 15px right and 3px down; release over a target | onDrop callback receives `{ itemId, targetId: <target id>, delta: { x: 15, y: 3 } }` |
| dnd-022 | drag-surface-config-input | DragSurface rendered with onDrop, describeItem, describeTarget, renderOverlay, axis, and keyboard all provided | Surface renders without error; describeItem/describeTarget values are used in announcements |
| dnd-023 | sortable-surface-config-input, sortable-drop-payload | SortableSurface rendered with onDrop, describeItem, describeZone, renderOverlay and orientation all provided; drag an item to a new place | Surface renders without error; onDrop receives all five payload fields; the describe values are used in announcements |
