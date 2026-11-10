
- **Single tab, no user action**: Drawer with one tab hides the strip and renders cleanly; tab count is fixed at initialization, so the strip's hidden state never needs to change after `init`.
- **Width clamped at init**: Initialize with `contentWidth: -50` or `999`. Value is clamped before NSDrawer receives it; user can drag within clamped range.
- **NaN width from string parsing**: If width is parsed from user defaults as `Double("nan")` or `Double("inf")`, fallback to 300 prevents invisible drawer.
- **Window closes while drawer open**: Weak reference to parent window prevents dangling pointer; drawer is cleaned up by NSWindow.
- **Window minimized**: Drawer auto-closes; `isOpen` becomes false; `closeIsAttributableToTheReader` is false (not attributed to user action).
- **Drawer edge flipped at screen boundary**: AppKit automatically flips drawer to opposite edge; no logic needed; caller receives same object with edge flipped.
- **Open called while opening**: AppKit's NSDrawer state machine handles overlapping calls; open is idempotent if drawer is already opening.
- **Tab ID invalid during select**: Invalid ID is silently ignored; drawer keeps showing current tab (fail-safe behavior to prevent blank drawer).
- **Parent window height = 0 at init**: Height is not cached from init; re-read at `open()` time, so construction order does not matter.
- **Bezel needs reinstall after NSDrawer rebuilds**: NSDrawer rebuilds NSDrawerFrame when edge changes or contentView is reassigned; `installBezelIfNeeded()` idempotently reattaches bezel to the current frame.

