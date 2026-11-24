
A markdown document editing component that pairs a source editor with a live preview pane. The component responds to viewport width: on wide viewports it displays editor and preview side-by-side in a split view; on narrow viewports it switches to a tabbed interface showing one pane at a time. Preview rendering is debounced to avoid expensive recalculation on every keystroke. The component remembers the user's last chosen layout mode and restores it when the viewport widens again.

