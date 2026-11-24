
- **open-and-close**: Component MUST support `open()` and `close()` methods to show and hide the drawer.
- **open-with-tab-selection**: Component MUST accept an optional tab ID in `open(selecting:)` to select a specific tab before opening.
- **toggle-state**: Component MUST support `toggle(selecting:)` to open on a tab if closed, or close if already open on that tab.
- **lazy-load-tabs**: Component MUST create a tab's view only on first access via `view(forTab:)`, and retain it thereafter. MUST cache views so repeated access returns the same instance. For an id that names none of the drawer's tabs, `view(forTab:)` MUST return `nil` and MUST NOT cache anything.
- **track-open-state**: Component MUST expose an `isOpen` boolean that is true while the drawer is open or transitioning to open, and false otherwise.
- **track-selected-tab**: Component MUST expose `selectedTabID`, identifying which tab is currently shown; it defaults to the first tab.
- **announce-visibility-changes**: Component MUST invoke `onVisibilityChange` after every open, close, or drag-initiated visibility change. A single change MAY produce more than one invocation.
- **honor-dragged-close**: Component MUST detect when the user drags the drawer closed at the outer edge, as distinct from a programmatic close, via the `closeIsAttributableToTheReader` property.
- **clamp-content-width**: Component MUST accept content width in the range 220–520 points; values outside this range MUST be clamped to the nearest bound. NaN and infinite values MUST fall back to the default width (300 points).
- **expose-content-width**: Component MUST expose `contentWidth` as a getter and setter, allowing the caller to read and persist the width the user dragged it to.
- **hide-single-tab-strip**: Component MUST hide the tab strip when fewer than two tabs are present at initialization.
- **use-tab-symbols**: Component MUST display a system symbol image for each tab in the strip, paired with the tab title.
- **use-theme-colors**: Component MUST paint the drawer's background using the theme's `windowBackground` role, and MUST repaint any border chrome drawn by the underlying platform control in the same role, so the drawer's edge does not mismatch the app's theme (e.g., a light system-drawn rim on a dark drawer).
- **sync-height-at-open**: Component MUST re-read the parent window's height at `open()` time, so a window assembled before toolbar growth or frame restoration is still sized correctly.
- **reapply-remembered-state-on-window-key**: Component MUST invoke `reapplyVisibility` when the parent window becomes key or main, so a caller can re-open a remembered drawer that was dropped during `init`.
- **accessibility-prefixed-ids**: Component MUST accept `accessibilityPrefix` and namespace all accessibility identifiers under it: `<prefix>` for the container, `<prefix>.tabs` for the strip, `<prefix>.tab.<id>` for the body.
- **release-delegate-on-deinit**: Component MUST clear any reference the underlying platform control holds back to this wrapper when the wrapper is deallocated, so the control cannot message a freed instance.

