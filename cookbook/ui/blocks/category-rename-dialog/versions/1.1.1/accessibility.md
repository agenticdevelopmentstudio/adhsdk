
- **Role**: Dialog with role implicit from Dialog component; input field is a text input.
- **Labels**: Input field MUST have `aria-label="New ${noun} name"` for screen readers.
- **Dialog title**: Dialog header contains `<DialogTitle>Rename {noun}</DialogTitle>` for context.
- **Dialog description**: Dialog header contains `<DialogDescription>This renames it everywhere it is used.</DialogDescription>`.
- **Keyboard navigation**: Input auto-focuses on dialog open; Tab moves between input and buttons; Enter submits; Escape closes (if not busy).
- **Error announcement**: Error text MUST be announced to screen readers; both `ErrorText` and its dialog-description variant always render the message with `role="alert"` whenever an error is present.
- **Announce loading state**: While `busy` is `true`, the confirm button SHOULD indicate loading (e.g., via aria-busy or button text change).
- **Minimum touch target**: Dialog buttons (Confirm, Cancel) MUST have touch targets of at least 44×44pt.

