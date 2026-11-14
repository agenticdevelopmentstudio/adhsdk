
- **Empty messages array**: Component renders the container and typing indicator (if not suppressed) even with no messages. The scrollback area is empty but focusable and keyboard-navigable.
- **selectedIndex out of range**: If `selectedIndex` is greater than or equal to the messages array length, no message receives `isSelected={true}` (all receive `isSelected={false}`). Component does not error.
- **selectedIndex is -1**: No message receives `isSelected={true}`. This is the default when the prop is omitted.
- **selectedIndex is less than -1**: Same behavior as -1 — no message receives `isSelected={true}`, and the component does not error.
- **isTyping true with empty messages array**: Typing indicator renders at the top of an otherwise empty container. Scroll position is at the bottom (no content to scroll to, so it is naturally at bottom).
- **Reader scrolled away from bottom**: If the transcript is not at (or within a small threshold of) the bottom when a new message arrives or `isTyping` changes, the view remains where the reader left it; arrival does not force a jump. Scrolling back near the bottom resumes auto-follow.
- **Rapid message arrivals**: If messages arrive faster than scroll-to-bottom can complete while the reader is at the bottom, the container remains scrolled to bottom — the underlying scroll observer re-triggers on every mutation, so it keeps pace with each new message.
- **fadeOlder with single message**: Single message remains at full opacity; fade gradient has no effect (no older messages to fade).
- **fadeOlder and scroll to top**: User scrolls to the top of the transcript to read the oldest message. That message transitions from faded to fully opaque as it enters the readable zone; no jarring opacity shift (the mask tracks scroll position continuously, not a discrete state change).
- **suppressTypingIndicator with isTyping true**: TypingIndicator is not rendered even though the component is aware typing is in progress; scroll-to-bottom still occurs on `isTyping` changes.
- **renderPopover returns null or undefined**: If renderPopover is called but returns null or undefined, nothing is rendered after the MessageBubble (React skips falsy children).
- **message.popover is falsy but renderPopover is provided**: No popover is rendered; renderPopover is not called.
- **onDetailArrowClick on message with no popover**: MessageBubble receives `showDetailArrow={false}` even if `showDetailArrows={true}`, so the detail arrow itself is not rendered — but if `onDetailArrowClick` was provided, the callback is still wired to that message; it simply has no arrow to trigger it.

