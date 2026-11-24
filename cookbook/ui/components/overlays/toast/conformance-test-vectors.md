
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| toast-001 | render-title | `useToast().add({ title: "Success" })` | Toast renders containing "Success" in title element |
| toast-002 | render-description | `useToast().add({ description: "Operation complete" })` | Toast renders containing "Operation complete" in description element |
| toast-003 | render-close-button | Toast rendered in viewport | Close button with X icon is visible and clickable |
| toast-004 | dismiss-on-close | User clicks close button | Toast animates out and is removed from viewport |
| toast-005 | enqueue-toasts | `useToast().add({ title: "Alert" })` called inside ToastProvider subtree | Toast appears in viewport |
| toast-006 | position-viewport-bottom-right | Viewport rendered in page | Viewport is positioned 1rem from the inline-end edge (right in left-to-right locales) and 1rem from the bottom edge of window (`fixed end-4 bottom-4`) |
| toast-007 | manage-z-index | Toast viewport and multiple page layers present | Toast viewport appears above other content at z-index 50 |
| toast-008 | animate-entrance | Toast added to queue | Toast element opacity transitions from 0 to 1 over transition duration |
| toast-009 | animate-exit | Close button clicked | Toast element opacity transitions to 0 over transition duration before removal |
| toast-010 | stack-toasts | Multiple toasts enqueued | Each toast renders below the previous with 0.5rem vertical spacing |
| toast-011 | constrain-width | Toast rendered at viewport width 1024px | Toast displays at a fixed width of 320px |
| toast-012 | constrain-width | Toast rendered at viewport width 320px | Toast width is capped to calc(100vw - 2rem) (32px total margin), narrower than the 320px fixed width |
| toast-013 | independent-provider-queues | Two `ToastProvider` instances mounted in separate subtrees, each with its own `useToast().add(...)` call | Each provider's viewport shows only the toasts added through its own `useToast()` instance |
| toast-014 | localize-close-label | `<Toaster closeLabel="Fermer" />` and a toast added | the close button's accessible label is `Fermer`; no button is labelled `Close` |
| toast-015 | respect-reduced-motion | Toast added; inspect the toast root and close button classes (jsdom has no media queries) | Both carry `motion-reduce:transition-none`, so the fade is disabled under reduced motion |
| toast-016 | enlarge-close-hit-area | Inspect the close button's classes | The close button is `inline-flex size-11` (44×44 CSS px) at `top-0 end-0` with the icon centred, and the toast root uses `pe-11` so text clears it |
| toast-017 | position-viewport-bottom-right | Render the viewport in a right-to-left locale | The viewport uses `end-4` (1rem from the inline-end edge, the left edge in RTL) and the close button uses `end-0`, so both mirror |
| toast-018 | auto-dismiss-timeout | Add a toast and wait 5000ms without hovering or focusing it | The toast closes itself |
| toast-019 | auto-dismiss-timeout | Add a toast and hover it for longer than 5000ms | The toast stays open until the pointer leaves |
| toast-020 | dismiss-on-escape | Focus inside a toast and press Escape | The toast is dismissed |
| toast-021 | dismiss-on-swipe | Drag a toast down past 40px | The toast is dismissed |
| toast-022 | set-explicit-limit | Mount `ToastProvider` with `limit={2}` and add three toasts | Two toasts are visible; the oldest is marked `data-limited` |
| toast-023 | use-design-tokens | Inspect the close button's color classes | Colors come from `apt-text-muted`, `apt-text` and `apt-gold/40`; no hardcoded color value |
