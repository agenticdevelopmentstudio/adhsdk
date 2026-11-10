
- **Role**: `main` — the `<main>` element provides the semantic role for the primary content of the document.
- **Focusability**: `tabIndex={-1}` (see **programmatic-focus**) makes the root a valid focus target for a scripted `.focus()` call — for example after a client-side route change — without adding it to the sequential (Tab-key) focus order. It makes no claim about what happens when a user clicks on Flow's children.
- **No label**: Flow is a structural container and does not require a label.
- **Keyboard interaction**: Flow itself does not handle keyboard events; scrolling in response to keys (arrow keys, Page Up/Down) is handled by whichever ancestor actually scrolls — normally the document (see **no-scroll-ownership**).

