
- **Role/trait**: None on the wrapper; the component is transparent and forwards semantic meaning to children.
- **Label requirements**: No label needed; the wrapper carries no semantic role.
- **Announce state changes**: Not applicable; state transitions are visual only and do not affect assistive technology.
- **Minimum tap target**: Not applicable; the component itself is not interactive.
- **Graceful degradation**: With JavaScript disabled, the server-rendered resting state is what ships, so content is never lost. The component does not guard against a missing `IntersectionObserver` global before constructing one in **arm-below-fold**; see Compliance.

