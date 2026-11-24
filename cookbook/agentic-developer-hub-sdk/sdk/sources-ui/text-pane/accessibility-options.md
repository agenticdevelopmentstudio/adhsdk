
- **Reduce Motion**: This component performs no animation of its own; text-view caret blinking is native platform behavior outside this component's control and is unrelated to the Reduce Motion setting. No special handling is required.
- **Increase Contrast**: The parent controller is responsible for choosing a high-contrast palette when applying the theme. The pane respects whatever foreground and background colors are provided.
- **Differentiate Without Color**: Text selection is drawn with `applyTheme`'s own selection colors, not a platform-chosen highlight: on macOS `applyTheme` sets `selectedTextAttributes` from the palette's selection background and selection text roles, and on iOS it tints the built-in selection UI via `tintColor` from the palette's cursor color. Whether the highlight is distinguishable without relying on color alone is therefore the palette's responsibility, not the platform's.

