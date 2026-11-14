
**Decision**: Use fully controlled props (`open`, `onClose`) rather than internal state.
**Rationale**: Requires the parent to manage `open` state and implement `onClose` dismissal, which enables precise parent control, simplifies testing, and aligns with React controlled-component patterns.
**Approved**: pending

**Decision**: Default `closeLabel` to `'← back'` when the caller does not supply one.
**Rationale**: Provides a sensible default for navigation-oriented overlays while still permitting per-caller customization.
**Approved**: pending

**Decision**: The overlay is intentionally non-modal: it always stays mounted and toggles visibility purely through CSS (`opacity`/`pointer-events`) rather than conditional mounting or `aria-hidden`/`inert`, and it defines no ARIA dialog role, no focus trap, no Escape-to-close, and no focus move on open or focus return on close.
**Rationale**: Keeps the component a lightweight, always-present layer suited to being toggled behind a persistent surface such as chat. The tradeoff is that the closed state's header, close button, and body remain keyboard-focusable and screen-reader-reachable (see **focus-management** in Compliance) until the source adds `inert`/`aria-hidden` gating.
**Approved**: pending

