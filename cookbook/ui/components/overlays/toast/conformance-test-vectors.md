
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| toast-001 | render-title | `useToast().add({ title: "Success" })` | Toast renders containing "Success" in title element |
| toast-002 | render-description | `useToast().add({ description: "Operation complete" })` | Toast renders containing "Operation complete" in description element |
| toast-003 | render-close-button | Toast rendered in viewport | Close button with X icon is visible and clickable |
| toast-004 | dismiss-on-close | User clicks close button | Toast animates out and is removed from viewport |
| toast-005 | enqueue-toasts | `useToast().add({ title: "Alert" })` called inside ToastProvider subtree | Toast appears in viewport |
| toast-006 | position-viewport-bottom-right | Viewport rendered in page | Viewport is positioned 1rem from right edge and 1rem from bottom edge of window |
| toast-007 | manage-z-index | Toast viewport and multiple page layers present | Toast viewport appears above other content at z-index 50 |
| toast-008 | animate-entrance | Toast added to queue | Toast element opacity transitions from 0 to 1 over transition duration |
| toast-009 | animate-exit | Close button clicked | Toast element opacity transitions to 0 over transition duration before removal |
| toast-010 | stack-toasts | Multiple toasts enqueued | Each toast renders below the previous with 0.5rem vertical spacing |
| toast-011 | constrain-width | Toast rendered at viewport width 1024px | Toast displays at a fixed width of 320px |
| toast-012 | constrain-width | Toast rendered at viewport width 320px | Toast width is capped to calc(100vw - 2rem) (32px total margin), narrower than the 320px fixed width |
| toast-013 | independent-provider-queues | Two `ToastProvider` instances mounted in separate subtrees, each with its own `useToast().add(...)` call | Each provider's viewport shows only the toasts added through its own `useToast()` instance |
| toast-014 | localize-close-label | Toast rendered with the active locale set to a non-English locale | Close button's accessible label text matches that locale's localized string, not the hard-coded English word "Close" |

