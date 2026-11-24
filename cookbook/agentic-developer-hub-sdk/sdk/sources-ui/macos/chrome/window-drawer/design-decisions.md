
**Lazy tab loading**
**Decision**: Tabs are views created on demand by a factory closure, not eagerly.
**Rationale**: This allows windows with many possible tabs to avoid upfront cost and memory bloat. A tab never opened costs nothing. Views are retained once made, avoiding repeated allocation if the user switches tabs multiple times.
**Approved**: pending

**Idempotent visibility callbacks**
**Decision**: `onVisibilityChange` may be called multiple times for a single open or close (once from the programmatic call, once from NSDrawer's delegate callback); callers MUST make their callbacks idempotent.
**Rationale**: This design avoids losing information: if the callback were called only once, a programmatic open made while the drawer is still animating would not notify, and an app that persists state would miss the change.
**Approved**: pending

**Width handling at init**
**Decision**: Width is clamped at initialization, before NSDrawer receives it, and NaN/infinity fall back to the default rather than being clamped to a bound.
**Rationale**: A bad remembered value (from a previous version or corrupt storage) cannot create an undraggable drawer this way. NaN and infinity carry no meaningful data, so the default is safer than a guess at which bound was meant.
**Approved**: pending

**Height re-read at open**
**Decision**: Height is not cached from `init`; it is re-read at `open()` time.
**Rationale**: Drawers are often built before their windows are fully assembled (before toolbar, before frame restoration). Reading height at open time makes construction order irrelevant; the drawer adapts to its window's final size automatically.
**Approved**: pending

**Bezel overlay for theme border**
**Decision**: A mouse-transparent `ThemedBackgroundView` overlay repaints AppKit's `NSDrawerFrame` border in the theme's window background color.
**Rationale**: `NSDrawerFrame` draws its border opaquely in the *system* appearance, which can produce a white rim around a dark theme drawer. AppKit's frame cannot be told what color to be, but a subview drawn after it can; making that subview mouse-transparent keeps the outer-edge drag that resizes the drawer working.
**Approved**: pending

**closeIsAttributableToTheReader**
**Decision**: A drawer closes for three reasons — programmatic `close()`, user drag, or window shutdown — and only the drag is attributable to the user's choice; the component exposes that distinction as a single boolean.
**Rationale**: An app that persists "drawer open" must know the difference: a drag close means remember closed, a programmatic close during teardown means ignore this, and window minimize means ignore this. The property answers "was this the user?" without the caller having to guess.
**Approved**: pending

**AccessibilityPrefix**
**Decision**: All accessibility IDs are namespaced under a required prefix.
**Rationale**: Multiple drawers in the same app (e.g., one per window) would otherwise collide in test automation or assistive technology. Making the prefix required, not optional, enforces the namespace discipline.
**Approved**: pending

