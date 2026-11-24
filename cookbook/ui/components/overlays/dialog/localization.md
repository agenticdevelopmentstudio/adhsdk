
Dialog renders one user-facing string: the close button's `aria-label="Close"`. That string is a literal hardcoded directly in `dialog.tsx`'s `DialogContent` — it is not supplied by Base UI — and it is not currently externalized or overridable via a prop. Composing components add their own translatable titles and descriptions via `DialogTitle` and `DialogDescription`.

