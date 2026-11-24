
- **Role/trait**: None: the container is deliberately not an accessibility element.
- **Label requirements**: None: nothing under the container is to be named, by design.
- **Announce state changes**: Not applicable: the container posts no accessibility notification; hiding from accessibility is its purpose.
- **Keyboard navigation**: Not applicable: the container takes no focus of its own; focus inside it is the contents' business.
- **Minimum tap target**: Not applicable: the container is not interactive.
- **Minimum contrast ratio**: Not applicable: the container sets no color.
- **inner-view-guard**: The container does not stop a view placed inside it from being an accessibility element; the source leaves that to the caller, as its comment says, because a hit test could still land on such a view. Callers hosting views inside it should make those views non-elements too (see `inner-views-not-elements`).

