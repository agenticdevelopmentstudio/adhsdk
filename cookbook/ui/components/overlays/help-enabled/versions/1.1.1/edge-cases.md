
- **Missing help entry, no fallback**: Renders plain text span. Caller's layout styles are preserved so the UI does not reflow. Console warning is emitted once.
- **Missing help entry, with fallback**: Popover opens with fallback text in an `info` flavor entry. No console warning is emitted because a fallback is provided.
- **Empty children prop**: Component will render an empty inline flex container with only the badge visible. This is allowed; the component does not validate input.
- **Very long children text**: Component does not limit text length. Layout depends on caller-provided `className` and page context.
- **Popover open, element removed from DOM**: Popover state is managed by the Popover component; behavior follows Popover's unmount logic.
- **Multiple renders with same `id` and no entry**: Warning is throttled by id; only one warning emitted per session even if component mounts/unmounts multiple times.
- **Touch devices (no hover)**: The badge's default reveal relies on `hover`, and touch devices have no hover state, so the badge does not become visible from touch input alone. It still reveals on keyboard focus (e.g., assistive technology's virtual cursor) and once the popover is open, and the trigger remains reachable by tapping it even while the badge sits at 0 opacity. This is an accepted limitation of the hover-based affordance, not a bug.

