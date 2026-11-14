
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| reveal-001 | visible-by-default | Component with children, JavaScript enabled, mounted but before any observer fires | Children render immediately in the resting state (full opacity, no transform) |
| reveal-002 | arm-below-fold | Component with children initially below viewport (top offset ≥ `window.innerHeight`), mounted | Armed indicator is applied to the wrapper (web: `lp-reveal--armed`); children are in the hidden state defined for the platform |
| reveal-003 | viewport-entry-detection, one-way-reveal | Component in armed state, user scrolls element into viewport | Intersection Observer fires; observer disconnects; armed indicator is removed (web: `lp-reveal--armed` removed); transition to the resting/visible state occurs |
| reveal-004 | one-way-reveal | Component revealed, user scrolls element out of viewport | Observer stays disconnected; element remains visible; no re-arming or re-hiding occurs |
| reveal-005 | armed-state-indicator | Component mounted below viewport | Armed indicator (web: `lp-reveal--armed` class) is present on the wrapper |
| reveal-006 | base-state-indicator | Component at any state | Base indicator (web: `lp-reveal` class) is always present on the wrapper |
| reveal-007 | classname-prop | Component below viewport at mount, with a custom class supplied | Custom class is included in the wrapper's class list alongside the base indicator and, while armed, the armed indicator |
| reveal-008 | children-forwarding | Component with children `<img src="..." />`, `<p>Text</p>` | Children are rendered as-is within the wrapper |
| reveal-009 | arm-below-fold | Component already on screen at mount (top offset less than `window.innerHeight`) | No Intersection Observer is created; no armed indicator is applied; children remain visible throughout the session |
| reveal-010 | delayed-reveal-margin | Component armed, user scrolls until the element's top edge is 12% of the viewport height above the bottom edge | Intersection Observer fires at that point; an unmodified (0-margin) observer would already have fired earlier, at the element's first visible pixel |
| reveal-011 | reduced-motion | Component armed (below the fold at mount) with the reduced-motion preference on, in a real browser | Computed `opacity` is `1` and computed `transform` is `none` even while `lp-reveal--armed` is present |

How to drive the vectors in a unit test: stub `IntersectionObserver` with a class that records the options it receives (so `rootMargin` can be asserted for reveal-010) and exposes a way to fire its callback with `isIntersecting: true`, and spy on `disconnect` (reveal-003, reveal-004). Stub `Element.prototype.getBoundingClientRect` to return a `top` below or above `window.innerHeight` to choose between arming (reveal-002) and the already-on-screen path (reveal-009, which also asserts the observer constructor is never called).
