
- **Role**: `region` — marks the container as a named landmark so screen reader users can navigate to the scrollback area.
- **Label**: aria-label set to the `label` prop value (or default "Conversation transcript"); allows the region to announce its purpose.
- **Focus management**: the scroll container is made keyboard-focusable so arrow keys can scroll it without a visible scrollbar. If the UI hides the scrollbar (e.g., a theme that uses a fade gradient instead), this focusable container ensures keyboard users are not locked out of scrollback — it is a focus target, not a focus trap; focus is never forced onto it and never held there.
- **Message bubbles**: each MessageBubble is responsible for its own semantics (e.g., button roles, labels for interactive elements); Transcript does not add semantic roles to individual messages.
- **Typing indicator**: TypingIndicator is responsible for announcing its own state; Transcript does not manage screen-reader announcements for typing.

