
**Decision**: Render children in the visible, resting state on initial render.
**Rationale**: Hiding content by default and revealing it conditionally is a content-loss bug if JavaScript fails; a reader with JS disabled sees the finished page, not a blank one. See **visible-by-default**.
**Approved**: pending

**Decision**: Disconnect the Intersection Observer immediately after the first intersection; a reveal is a one-way transition.
**Rationale**: Re-hiding content that has scrolled past is a well-known anti-pattern that makes pages feel broken. See **one-way-reveal**.
**Approved**: pending

**Decision**: Read `prefers-reduced-motion` from a CSS media query rather than in JavaScript.
**Rationale**: This keeps a single source of truth: if the media query in the stylesheet omits animation, the browser's preference is respected without re-reading it in code. The component still arms and unarms; the transition is neutralized.
**Approved**: pending

**Decision**: Configure the Intersection Observer with a bottom root margin of -12% of the viewport height.
**Rationale**: This delays the reveal until the element's top edge is 12% of the viewport height above the bottom — later than an unmodified (0-margin) observer, which would already fire at the element's first visible pixel — so the fade-in reads as a deliberate reveal rather than firing the instant the element's edge appears. See **delayed-reveal-margin**.
**Approved**: pending

