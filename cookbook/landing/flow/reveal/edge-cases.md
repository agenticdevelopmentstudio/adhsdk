
- **Already on screen at mount**: see **arm-below-fold**. This prevents the blank-out flicker that would occur if the element were armed and then immediately intersected.
- **Root margin offset**: see **delayed-reveal-margin**.
- **Null ref**: If the ref is null when the effect runs (the ref is not attached to an element), the effect returns early and does not proceed with observation.
- **Multiple child updates**: The component re-renders if children change. The ref to the wrapper element is stable; the observer (if created) remains active unless already disconnected by intersection.
- **Window resize**: The Intersection Observer automatically adapts to viewport changes; no resize listener is needed.
- **Cleanup on unmount**: The cleanup function disconnects the observer if one was created, preventing memory leaks.
- **Keyboard focus inside an armed element**: An armed element is invisible (opacity 0) but its children stay focusable, and Reveal has no focus handler of its own. Moving focus into it scrolls the child into view like any other scroll, and the reveal fires only when the observer reports an intersection past the bottom margin (see **delayed-reveal-margin**); a focus scroll that stops short of that leaves the focused child hidden. Focus does not itself trigger the reveal.
- **IntersectionObserver unavailable**: See the **No guard for a missing IntersectionObserver** design decision.
