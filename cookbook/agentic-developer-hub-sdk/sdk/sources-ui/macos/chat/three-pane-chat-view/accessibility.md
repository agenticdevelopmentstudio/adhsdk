
- **Role/trait**: Composite container with semantically structured panes; topics pane is a list of selectable items, transcript is a scrollable region, detail pane is a dynamic content region.
- **Label requirements**: Topics MUST have accessible labels (title and description); messages MUST have accessible content (text or aria-label); detail pane MUST announce its active topic when it updates.
- **Announce state changes**: When a topic is activated, the accessibility tree MUST be updated to reflect the active topic and detail pane content. When connectors render, their presence MUST not interfere with text reader navigation.
- **Keyboard navigation**: Arrow up/down MUST navigate between visible topics, including while the chat input has focus (see **arrow-key-navigation**). Single-character keystrokes (without modifiers) MUST focus the chat input when focus is not already in an input. Tab MUST navigate between focusable regions (topics list, transcript, input, detail pane links).
- **Minimum tap target**: Topics list items and messages MUST have a minimum touch target of 44×44pt on mobile platforms, 48×48dp on Android.
- **Assistive technology**: Screen readers MUST announce the count and titles of topics. Connectors are visual only and MUST NOT clutter the accessible tree.

