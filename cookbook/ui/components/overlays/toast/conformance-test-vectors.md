
| toast-015 | respect-reduced-motion | Toast added with `prefers-reduced-motion: reduce` active | The opacity fade is disabled or shortened |
| toast-016 | enlarge-close-hit-area | Measure the close button's hit box | The hit box is at least 44×44 CSS px |
| toast-017 | position-viewport-bottom-right | Render the viewport in a right-to-left locale | The viewport sits 1rem from the left (inline-end) edge, and the close button is offset from the toast's left edge |
| toast-018 | auto-dismiss-timeout | Add a toast and wait 5000ms without hovering or focusing it | The toast closes itself |
| toast-019 | auto-dismiss-timeout | Add a toast and hover it for longer than 5000ms | The toast stays open until the pointer leaves |
| toast-020 | dismiss-on-escape | Focus inside a toast and press Escape | The toast is dismissed |
| toast-021 | dismiss-on-swipe | Drag a toast down past 40px | The toast is dismissed |
| toast-022 | set-explicit-limit | Mount `ToastProvider` with `limit={2}` and add three toasts | Two toasts are visible; the oldest is marked `data-limited` |
| toast-023 | use-design-tokens | Inspect the close button's color classes | Colors come from `apt-text-muted`, `apt-text` and `apt-gold/40`; no hardcoded color value |
