
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `dnd.grip.reorder` | "Reorder" | DragGrip aria-label when no `subject` is given |
| `dnd.grip.reorder-subject` | "Reorder {subject}" | DragGrip aria-label when `subject` is given |
| `dnd.announce.picked-up` | "Picked up {item}." | Drag-start announcement (SortableSurface, DragSurface) |
| `dnd.announce.over-target` | "{item} is over {target}." | Drag-over announcement when over a zone, item, or target |
| `dnd.announce.over-none` | "{item} is over no drop target." | Drag-over announcement when over nothing |
| `dnd.announce.dropped` | "{item} was dropped." / "{item} was dropped on {target}." | Drag-end announcement |
| `dnd.announce.returned` | "{item} was returned to where it started." | SortableSurface drag-end announcement when dropped with no target |
| `dnd.announce.cancelled` | "Dragging {item} was cancelled." | Drag-cancel announcement |

These strings are hardcoded English in the reference implementation. `describeItem`, `describeZone`, and `describeTarget` let the host localize the item/zone/target *name* substituted into each sentence, but the surrounding sentence itself is not externalized or overridable — a fully localized host must currently accept the English announcement wording as-is.

