
- **render-children**: Component MUST render its `children` prop as-is without modification or wrapping in additional elements beyond the anchor div itself.
- **relative-positioning**: Component MUST apply `position: relative` CSS to establish a positioning context for absolutely positioned children.
- **class-concatenation**: Component MUST concatenate the string `hover-popover-anchor` with any `className` prop value. If `className` is provided, the final class MUST be `hover-popover-anchor <className>`. If `className` is not provided, the class MUST be exactly `hover-popover-anchor`.
- **leave-callback**: Component MUST accept an optional `onMouseLeave` callback and invoke it when the pointer leaves the anchor element (exiting both trigger and panel boundary).
- **preserve-hover-across-elements**: Component MUST ensure that moving the pointer from the trigger to the panel (or vice versa) does NOT trigger the `onMouseLeave` callback, because both elements are contained within the same anchor div.
- **panel-in-anchor-flow**: The panel rendered as a child of the anchor MUST remain a normal DOM descendant of the anchor (not rendered through a portal). It MAY be visually offset outside the anchor's own box (for example via absolute positioning), but if so, every point the pointer can cross between the trigger and the panel MUST hit-test to a DOM descendant of the anchor — for example a bridging element spanning the gap — or **preserve-hover-across-elements** does not hold for that crossing.

