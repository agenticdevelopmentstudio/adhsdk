
- **render-content-in-vertical-stack**: The component MUST render the heading (if provided), all rows, and the Done button in a vertical stack with consistent spacing and alignment.
- **accept-custom-rows**: The component MUST accept an array of NSView subclasses as row content and render them without modification or filtering.
- **support-dynamic-heading**: The component MUST allow the heading text to be changed after initialization via the `heading` property, with the UI updating immediately to reflect the change or hide the heading if set to `nil`.
- **no-change-buffering**: The component MUST NOT provide a commit or cancel step, and MUST NOT buffer row changes itself; rows are responsible for applying and persisting or propagating their own changes as they occur.
- **provide-done-callback**: The component MUST invoke the `onDone` callback when the Done button is pressed, allowing the presenter to decide how to close the dialog (sheet dismissal, modal stop loop, etc.).
- **provide-close-callback**: The component MUST invoke the `onDidClose` callback once the dialog is off-screen, signaling the end of any pending row control gestures and allowing the presenter to finalize state.
- **set-return-key-equivalent**: The Done button MUST have Return (Carriage Return, `\r`) as its key equivalent, enabling keyboard activation.
- **support-accessibility-identification**: The component MUST assign accessibility identifiers to the dialog container (`<prefix>.dialog`) and Done button (`<prefix>.dialog.done`), where `<prefix>` is customizable at initialization and defaults to `"options"`.
- **respect-row-width-constraint**: The component MUST size each row to the full width of the dialog minus left and right insets, preventing row content from narrowing the dialog.
- **use-minimum-width-floor**: The component MUST apply a minimum width constraint (not an exact width) so that row content wider than the default width can expand the dialog; this allows the dialog to grow as needed while maintaining a baseline size.

