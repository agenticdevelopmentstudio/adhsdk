
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| anchor-001 | render-children | `children` = `<button>Trigger</button><div>Panel</div>` | Anchor renders both children in order without wrapping them in additional elements |
| anchor-002 | relative-positioning | Anchor rendered with no props | Computed style includes `position: relative` |
| anchor-003 | class-concatenation | `className` = `"custom-class"` | Final class attribute is `"hover-popover-anchor custom-class"` |
| anchor-004 | class-concatenation | No `className` prop | Final class attribute is exactly `"hover-popover-anchor"` |
| anchor-005 | leave-callback | `onMouseLeave` callback provided, pointer leaves anchor | Callback is invoked exactly once |
| anchor-006 | preserve-hover-across-elements | Pointer on trigger, moves to panel sibling | `onMouseLeave` is NOT invoked (anchor still contains pointer) |
| anchor-007 | leave-callback | `onMouseLeave` not passed, pointer leaves anchor | No error is thrown; the anchor still renders and functions as a positioning context |
| anchor-008 | preserve-hover-across-elements | Pointer enters the anchor, leaves, enters again, leaves again (two full enter/leave cycles) | `onMouseLeave` is invoked exactly twice — once per exit, never coalesced |
| anchor-009 | panel-in-anchor-flow | Panel child rendered with a margin that visually offsets it outside the anchor's box, with no other element spanning the gap; pointer moves from the trigger across that gap toward the panel | `onMouseLeave` fires when the pointer crosses the gap, because that point does not hit-test to a DOM descendant of the anchor |
| anchor-010 | panel-in-anchor-flow | Panel child rendered via `ReactDOM.createPortal` to `document.body` instead of as a direct child | The panel is not a DOM descendant of the anchor element; pointer movement into the panel is not guaranteed to stay within the anchor's boundary |
| anchor-011 | panel-in-anchor-flow | Panel child rendered with a margin that visually offsets it outside the anchor's box, plus a bridging element that is itself a DOM descendant of the anchor and spans the gap (for example a pseudo-element on the panel); pointer moves from the trigger across the gap toward the panel | `onMouseLeave` does NOT fire; every point along the crossing hit-tests to a DOM descendant of the anchor (the bridge) |

