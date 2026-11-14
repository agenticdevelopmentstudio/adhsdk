
- **Mode control role**: Segmented control (see **accessibility-labels-macos**). Labeled "Editor Mode" via an explicit accessibility label on macOS (`setAccessibilityLabel`). On iOS, no group-level label is set in source; VoiceOver reads each segment by its own title (the mode's `label`, e.g. "Edit", "Preview", "Split"), since `UISegmentedControl` exposes per-segment titles as accessibility labels by default.
- **Mode control accessibility ID** (macOS): "markdown-editor.mode"
- **Help button role**: Button. Labeled "Markdown Syntax Help" via an explicit accessibility label on macOS. On iOS, no explicit label is set in source; VoiceOver reads the button's own title, "?", which does not convey the button's purpose (see Compliance: screen-reader-support).
- **Help button accessibility ID** (macOS): "markdown-editor.help"
- **Import button role**: Button. Labeled "Open Markdown File" via an explicit accessibility label on macOS. On iOS, no explicit label is set in source; VoiceOver reads the button's own title, "Open…".
- **Import button accessibility ID** (macOS): "markdown-editor.import"
- **Minimum touch target size** (iOS): Apple HIG recommends 44×44pt. The bar's 44pt height minus the stack's 4pt top/bottom padding leaves at most 36pt of vertical space for the arranged controls, so the 44pt minimum is not guaranteed by layout alone (see Compliance: touch-target-size).
- **Keyboard navigation**: See **keyboard-activation**: all buttons are keyboard-focusable and activatable via Return/Space (platform default).
- **Announcements**: See **selection-announcement**. The source makes no explicit announcement call; the selection change reaches assistive technology only through the platform segmented control's own accessibility behavior.

