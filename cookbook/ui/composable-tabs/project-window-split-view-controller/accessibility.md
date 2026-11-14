
- **Role/trait**: Not set in source; the platform's split view role applies to the divider and panes unmodified.
- **Label requirements**: Not applicable: the component renders no label of its own; the pane contents carry their own labels.
- **Announce state changes**: NEEDS REVIEW: Not implemented in source. Showing or hiding the shelf posts no accessibility notification and sets no label on the divider; evidence needed is a screen reader pass on a shelf toggle to see whether the platform announces the layout change by itself.
- **keyboard-toggle-shelf-panel**: A keyboard user MUST be able to show and hide the shelf through the shelf-panel toggle (documented in source as the Command-0 and Command-1 keys), which also puts the keyboard in the shelf's filter.
- **keyboard-divider-resize**: NEEDS REVIEW: Not implemented in source. No keyboard path adjusts the divider; width changes by keyboard are limited to the show and hide toggles; evidence needed is whether the platform's split view exposes a keyboard divider adjustment that applies here.
- **Minimum tap target**: Not applicable: the component defines no control; the divider's grab area is the platform split view's.
- **Minimum contrast ratio**: Not applicable: the component picks backdrop colors from the theme palette and draws no foreground; contrast belongs to the theme and the pane contents.

