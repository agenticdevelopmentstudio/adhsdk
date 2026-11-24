
- **Decision**: Use an app-modal dialog centered on the screen instead of a popover anchored to the gear button.
  **Rationale**: A popover anchored to the gear would move as the window resizes (sliders change size). An app-modal dialog centered on the screen remains stable during interactive adjustments, providing a better user experience when live slider adjustments change the window's dimensions.
  **Approved**: pending

- **Decision**: Build controls from a closure at dialog open time, not construction time.
  **Rationale**: Building controls from a closure at open time ensures they reflect live state, even if other UI or keyboard shortcuts have changed settings while the dialog was closed. This avoids stale UI and prevents the need for complex state synchronization.
  **Approved**: pending

- **Decision**: Make the dialog's `title` settable at runtime, triggering a control rebuild.
  **Rationale**: Paned or tabbed windows may change their displayed name based on content. Allowing the title to be updated and triggering a control rebuild ensures the dialog's context remains correct.
  **Approved**: pending

- **Decision**: Track and match the host window's level for the duration of the dialog session.
  **Rationale**: The dialog matches the host window's level so that options for a floating or docked window remain accessible. Without this, a dialog could appear behind its own window if the host's level changed, confusing the user.
  **Approved**: pending

- **Decision**: Make the dialog's body width configurable at construction time.
  **Rationale**: Not all options are simple checkboxes and sliders. Some dialogs may need wider rows (e.g., a picker or a button row). Configurable width avoids over-constraining the layout and supports diverse use cases.
  **Approved**: pending

- **Decision**: Expose gear button creation as a static factory (`makeGearButton()`), independent of a dialog instance.
  **Rationale**: A host window without a full dialog (e.g., one that shows options in a menu instead) can still use the same, consistent gear button appearance.
  **Approved**: pending

- **Decision**: Route the window's close button through the dialog's own `close()` logic rather than letting AppKit close the window directly.
  **Rationale**: Letting the close button directly close the window would bypass the modal session end logic, leaving the app in a modal loop with no window on screen. Routing it through `close()` ensures clean teardown.
  **Approved**: pending

- **Decision**: Center the reset button under the rows instead of stretching it to the full dialog width.
  **Rationale**: A full-width reset button would visually group with the control rows above, making it look like another option rather than a separate action. Centering it distinguishes its role.
  **Approved**: pending

