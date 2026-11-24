
- **Container height**: fills available space; typically a fixed-height or flex-layout container within a larger chat UI.
- **Overflow**: vertical scroll only; horizontal scroll not expected.
- **Message spacing**: determined by `MessageBubble` styling; Transcript does not add extra padding between messages.
- **Fade gradient** (when `fadeOlder` is true): viewport-anchored opacity mask from fully transparent at the top to fully opaque at the bottom; older messages approach transparency as they scroll toward the top; no explicit duration specified for the fade transition (governed by scroll position, not animation timing).
- **Typing indicator spacing**: rendered below all messages with standard line height; inherits typography from `TypingIndicator`.

