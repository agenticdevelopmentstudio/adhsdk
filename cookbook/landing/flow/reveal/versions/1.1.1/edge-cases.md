
- **Already on screen at mount**: see **arm-below-fold**. This prevents the blank-out flicker that would occur if the element were armed and then immediately intersected.
- **Root margin offset**: see **delayed-reveal-margin**.
- **Null ref**: If the ref is null when the effect runs (component was unmounted before effect execution), the effect returns early and does not proceed with observation.
- **Multiple child updates**: The component re-renders if children change. The ref to the wrapper element is stable; the observer (if created) remains active unless already disconnected by intersection.
- **Window resize**: The Intersection Observer automatically adapts to viewport changes; no resize listener is needed.
- **Cleanup on unmount**: The cleanup function disconnects the observer if one was created, preventing memory leaks.

