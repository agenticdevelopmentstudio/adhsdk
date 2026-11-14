
- **role**: Dialog with role implicit from Dialog component; input field is a text input.
- **input-label**: Input field MUST have `aria-label="New ${noun} name"` for screen readers.
- **dialog-title**: Dialog header contains `<DialogTitle>Rename {noun}</DialogTitle>` for context.
- **dialog-description**: Dialog header contains `<DialogDescription>This renames it everywhere it is used.</DialogDescription>`.
- **keyboard-navigation**: Input auto-focuses on dialog open; Tab moves between input and buttons; Enter submits; Escape closes (if not busy).
- **error-announcement**: Error text MUST be announced to screen readers; both `ErrorText` and its dialog-description variant always render the message with `role="alert"` whenever an error is present.
- **announce-loading-state**: While `busy` is `true`, the loading indicator that replaces the buttons MUST be announced to assistive technology (`role="status"`), per **show-loading-state**.
- **minimum-touch-target**: Dialog buttons (Confirm, Cancel) MUST have touch targets of at least 44×44 CSS px on web (44×44pt on iOS and macOS, 48×48dp on Android).

