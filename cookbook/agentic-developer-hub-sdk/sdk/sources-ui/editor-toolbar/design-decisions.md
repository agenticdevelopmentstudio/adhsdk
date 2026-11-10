
**Decision**: Use a fixed height per platform — 44pt on iOS, 32pt on macOS.
**Rationale**: iOS follows the Apple HIG standard button height; macOS follows the macOS toolbar standard. The different heights reflect platform conventions, not functional differences.
**Approved**: pending

**Decision**: Hide the segmented control when only one mode is available.
**Rationale**: Reduces visual clutter and simplifies the toolbar when there is nothing to switch between; the mode value is still tracked internally and can be changed programmatically.
**Approved**: pending

**Decision**: Insert a flexible spacer between the mode control and the buttons.
**Rationale**: Ensures the help and import buttons align to the right edge, following common toolbar patterns.
**Approved**: pending

**Decision**: Set explicit accessibility labels for the mode control, help button, and import button on macOS; rely on system title inference on iOS.
**Rationale**: The "?" title is ambiguous for screen readers, so macOS sets explicit labels ("Editor Mode", "Markdown Syntax Help", "Open Markdown File"). iOS has no equivalent explicit labels in source; VoiceOver falls back to reading each control's own title text, which is a real gap for the help button (see Compliance: screen-reader-support).
**Approved**: pending

**Decision**: Present help as a transient `NSPopover` on macOS and a modal sheet on iOS.
**Rationale**: Reflects each platform's norm for supplementary information windows — a dismiss-on-blur popover on macOS, a modal presentation on iOS.
**Approved**: pending

**Decision**: Make all three callbacks (`onModeChange`, `onImport`, `onSyntaxHelpRequested`) optional.
**Rationale**: Lets a host ignore mode changes by leaving `onModeChange` unset, or suppress the help button entirely via `showsHelpButton = false`, without requiring stub callbacks.
**Approved**: pending

