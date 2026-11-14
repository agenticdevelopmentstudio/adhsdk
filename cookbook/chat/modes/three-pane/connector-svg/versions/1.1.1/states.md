
The component has no user-facing state (no pressed, disabled, or focused variants) and its rendering is not driven by user interaction. It does hold internal derived state: computed line and circle geometry, cached and recomputed only on layout-affecting events (see **recompute-on-input-change**, **resize-observer-updates**, **window-resize-updates**, **scroll-updates**).

