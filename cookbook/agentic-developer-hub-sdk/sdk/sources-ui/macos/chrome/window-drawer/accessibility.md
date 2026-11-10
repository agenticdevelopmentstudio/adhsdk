
- **Role**: Container is a group; tab strip is a button group (NSSegmentedControl); each tab is a button-like segment.
- **Label requirements**: Each segment is labeled with its tab title (from `DrawerTab.title`). System symbol images include `accessibilityDescription` (title) for screen readers.
- **Announce state changes**: Tab selection change MUST update the body's accessibility ID to `<prefix>.tab.<id>` so screen readers track the active pane. Visibility changes do not require additional announcement (caller handles state memory).
- **Control size**: Tab strip uses NSSegmentedControl's default `.regular` control size (about 24–28pt tall). macOS HIG sizes pointer-driven controls by control size, not by the 44×44pt touch-target minimum that applies on iOS; no additional minimum is imposed here.
- **Keyboard navigation**: Tab selection MUST be operable via arrow keys and Return (NSSegmentedControl standard behavior); drawer open/close MUST be programmatic or draggable, not keyboard-initiated.

