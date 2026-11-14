
- **Role/trait**: Drawer is rendered as a Dialog (via Base UI `Dialog` primitive), which is announced as a dialog by screen readers.
- **Label requirements**: The drawer MUST have an accessible name at all times — supplied by SheetTitle (auto-associated by Base UI Dialog via `aria-labelledby`) or, when no visible title is used, by an `aria-label` prop passed to SheetContent (accepted via **content-composition-props**).
- **Announce state changes**: Base UI Dialog handles focus management and announces opening/closing to screen readers.
- **Minimum tap target**: The close button's `size="icon-sm"` Button variant renders at 1.75rem (28px) square (`size-7`, per `button.tsx`), below the 44×44pt minimum — this is a known failure, not an enforced minimum.
- **Keyboard navigation**: Base UI Dialog primitive handles Escape key to close and focus trapping within the drawer. Source code relies on these inherited behaviors.
- **Screen reader text**: Close button includes a screen-reader-only label ("Close") — invisible on screen but exposed to assistive technology (see **close-button-accessible-label**).

