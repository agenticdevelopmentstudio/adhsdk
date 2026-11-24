
1. **Decision**: The component makes no assumptions about how it is presented (sheet, modal window, custom container); the presenter supplies the `onDone` and `onDidClose` callbacks.
   **Rationale**: The component cannot know how closing should be handled by every possible container, and duplicating the layout logic across multiple presentation contexts would mean two places for it to drift apart.
   **Approved**: pending

2. **Decision**: Rows apply their own changes as they are made rather than the component collecting changes and applying them on a commit operation.
   **Rationale**: This is appropriate for settings dialogs where preview is useful and the cost of reverting a change is low. For dialogs with destructive or expensive operations, the caller must add confirmation logic in the row control itself.
   **Approved**: pending

3. **Decision**: The `heading` property is settable and observable via `didSet`, updating the label's text and visibility in real time.
   **Rationale**: Dialogs named after their content (e.g., "Preferences for: FPS Meter") may be renamed while the dialog is presented; a frozen heading would misname the dialog.
   **Approved**: pending

4. **Decision**: The dialog's width uses a `>=` (floor) constraint rather than an exact width.
   **Rationale**: This allows rows wider than the default 340pt to expand the dialog, preventing truncation of long labels or UI elements that should remain fully visible (e.g., a popup with many options). An exact width would sacrifice row compression resistance, leading to truncated content.
   **Approved**: pending

5. **Decision**: The `accessibilityPrefix` parameter namespaces both the dialog's and the Done button's accessibility identifiers.
   **Rationale**: Multiple dialogs can coexist on screen with distinct accessibility IDs, which is essential for UI testing scenarios.
   **Approved**: pending

6. **Decision**: The Done button's key equivalent is set to Return (`"\r"`).
   **Rationale**: Return is the standard macOS convention for confirming dialogs; setting `keyEquivalent = "\r"` makes Done the default action for the Return key, improving keyboard navigation and accessibility.
   **Approved**: pending

7. **Decision**: Each row is pinned to the stack's width minus the left and right insets using a single constraint per row.
   **Rationale**: This ensures consistent indentation and lets row content expand or contract with the dialog without special handling in individual row controls.
   **Approved**: pending

