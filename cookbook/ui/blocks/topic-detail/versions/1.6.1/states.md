
| State | Appearance change |
|---|---|
| no selection | no active item (bar may sit on an active rail slot) |
| item active | gold left bar + gold text + `aria-current="true"` |
| item hover | text-colored left bar (if `hoverBar=true`) |
| item disabled | dimmed text, non-clickable |
| item blocked | amber dot on icon + sr-only announcement |
| rail collapsed | thin strip (48px) with `»` expand control |
| rail dragging | transition suppressed, tracks pointer live |
| delete pending | confirmation dialog open, spinner during async delete |
| batch: checkbox checked | box shows check mark |
| batch: checkbox unchecked | box empty |
| covered style | icon-only left-aligned strip |
| ≤768px | single-column grid: rail stacks above the pane, unchanged vertical list with left bar and `border-r`; collapse toggle and drag-resize handle hidden |
| `busy=true` | spinner visible in header / top-right of untitled header |
| `railSlot` active | gold bar on the slot (when nothing in list is selected) |
| selection style "marker" | full-height left dash (root) + connector line (hierarchical) instead of bar |

