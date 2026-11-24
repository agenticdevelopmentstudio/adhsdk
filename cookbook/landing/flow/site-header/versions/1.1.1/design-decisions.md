
**Decision**: The header scrolls away with page content rather than staying fixed.
**Rationale**: Flow pages have varied band backgrounds, and a fixed header would have to render opaque over all of them to stay legible, which would permanently cover the diagonal-seam geometry the layout is built on. A header that scrolls away with the hero costs a reader one flick back to the top and keeps the seams intact.
**Approved**: pending

**Decision**: Use a `ResizeObserver` on the drawer wrapper element instead of duplicating the breakpoint with `matchMedia` in JavaScript.
**Rationale**: The wrapper's visibility is decided by the CSS media query in `flow.css`; observing the wrapper's bounding box lets the observer read that decision rather than restating the breakpoint a second time in JavaScript, keeping the CSS as the single source of truth if the breakpoint value changes.
**Approved**: pending

**Decision**: Remount `NavChrome` (via a generation counter) only on the narrow-to-wide transition, when the drawer wrapper goes from visible to hidden.
**Rationale**: `NavChrome` owns its open state internally and exposes no way to close it. Left open across a resize past the breakpoint, its Tab-trap listener would stay attached to a `display: none` subtree and block Tab on the rest of the page; remounting on the way out drops the listener with the component. See **reset-drawer-state**.
**Approved**: pending

**Decision**: `brand` is never passed to `NavChrome` in the drawer.
**Rationale**: The header already displays the brand; rendering it a second time inside the drawer's own bar would draw a duplicate wordmark.
**Approved**: pending

**Decision**: Navigation links are real `<a>` elements that stay in the DOM even where CSS hides them, rather than being removed or duplicated.
**Rationale**: Below the breakpoint, the bar's `<nav>` stays in the DOM and is hidden purely by the CSS media query (see **bar-nav-visible-at-breakpoint**), so a crawler or an assistive-technology link rotor can still discover the destinations. Under `bar='drawer'`, the links are not rendered in the bar at all — a JSX conditional, not a CSS hide — so the drawer's copy is the only destination discovered, avoiding duplicate in-page links.
**Approved**: pending

**Decision**: `barLinks` is optional and defaults to `links`.
**Rationale**: A host with few enough links to fit both the bar and the drawer need not supply two lists; a host with many sections can pass a shorter `barLinks` for the bar while the drawer still receives the full `links` array (see **pass-full-links**).
**Approved**: pending

