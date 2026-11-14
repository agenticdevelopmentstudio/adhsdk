
- **auto-dismiss-timeout**: A toast MUST close itself after a timeout, 5000ms by default, and the countdown MUST pause while the toast is hovered or holds focus.
- **dismiss-on-escape**: Pressing Escape while focus is inside a toast MUST dismiss it.
- **dismiss-on-swipe**: A toast MUST be dismissible by swiping it down or to the right past a 40px threshold.
- **set-explicit-limit**: Implementations SHOULD pass an explicit `limit` to `ToastProvider` to bound the number of simultaneously visible toasts.
- **use-design-tokens**: Implementations MUST use the design tokens `apt-text-muted`, `apt-text` and `apt-gold/40` for the close button's rest, hover and focus-ring colors, and MUST NOT hardcode a color value.
