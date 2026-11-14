
- **Multiple children**: Component accepts ReactNode, which can be a single element, multiple elements, or a fragment. Children are rendered without iteration or mapping, so the developer is responsible for uniqueness and key management.
- **Null or undefined children**: If `children` is null or undefined, the anchor renders an empty div. This is valid and matches React's children handling.
- **Callback not provided**: If `onMouseLeave` is not passed, no callback is invoked. The anchor still functions as a positioning context. This is the expected behavior for a pure layout component.
- **Rapid pointer entry/exit**: If the pointer enters and exits the anchor repeatedly within a single event cycle (enter → leave → enter → leave), see **leave-per-exit**.
- **Panel offset outside the anchor's box**: A panel offset by a margin or transform with nothing hit-testable spanning the gap fires `onMouseLeave` on the crossing, even though trigger and panel look contiguous. A bridging descendant of the anchor avoids it. See **panel-in-anchor-flow** (anchor-009, anchor-011).
- **Panel rendered in a portal**: A panel rendered through `ReactDOM.createPortal` is not a DOM descendant of the anchor, so the containment guarantee does not extend to it. See **panel-in-anchor-flow** (anchor-010).

