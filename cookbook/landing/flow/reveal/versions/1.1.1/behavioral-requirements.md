
- **visible-by-default**: The initial render MUST be the resting (visible) state. Arming only happens after mount, so a reader with JavaScript disabled never sees a hidden state.
- **viewport-entry-detection**: The component MUST use the Intersection Observer API to detect when the wrapped element enters the viewport.
- **arm-below-fold**: On mount, the component MUST check whether the element's top offset is already less than `window.innerHeight`. If so, the component MUST NOT create an Intersection Observer and MUST NOT apply the armed indicator — the element is treated as already revealed. Otherwise the component arms and creates the observer.
- **delayed-reveal-margin**: The Intersection Observer MUST be configured with a bottom root margin that delays the reveal until the element's top edge is 12% of the viewport height above the bottom (`rootMargin: '0px 0px -12% 0px'`). A negative bottom margin shrinks the observer's root rect, so this fires later than an unmodified (0-margin) observer would — not earlier.
- **one-way-reveal**: The component MUST disconnect the Intersection Observer immediately after the first intersection is detected; the element MUST NOT re-arm or re-hide when scrolled past.
- **armed-state-indicator**: While armed (observing but not yet shown), the wrapper MUST carry an observable marker distinguishing it from the resting state (see Platform Notes for the web implementation).
- **base-state-indicator**: The wrapper MUST always carry an observable base-state marker, independent of armed/revealed state (see Platform Notes for the web implementation).
- **classname-prop**: The component MAY accept an optional prop to let consumers add custom classes to the wrapper element.
- **children-forwarding**: The component MUST render its children as-is within the wrapper element.

