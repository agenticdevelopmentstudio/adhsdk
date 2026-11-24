
- **No brand prop**: Component renders the header without a brand div.
- **No links provided**: NavChrome and the nav bar receive an empty array; the component still renders but shows no navigation items.
- **No action prop**: The action div is not rendered.
- **Viewport resize across the breakpoint with the drawer open**: A `ResizeObserver` on the drawer wrapper detects the transition from visible to hidden (narrow to wide, under `bar='nav'`) and remounts `NavChrome` via a generation-counter increment, clearing its internal open state. The remount fires only on that visible-to-hidden transition, not when the wrapper is already hidden. See **reset-drawer-state**.
- **bar='drawer' never triggers a remount**: The drawer wrapper is never hidden in this mode, so the visible-to-hidden transition the observer watches for never happens. See **drawer-visibility**.
- **barLinks defaults to links**: If `barLinks` is not provided, it defaults to `links`, so the same links array is used in both the bar and the drawer.
- **NavChrome state persistence**: `NavChrome` owns its open state and exposes no public API to close it; remounting is the only way to reset that state, which is why the generation counter is used.

