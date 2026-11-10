
- Renders the shared, focusable `<button>` primitives, so keyboard activation
  (Space/Enter) works natively.
- Initial focus is placed deliberately: on the confirm button by default, and on
  the cancel button for `destructive` actions so an errant Enter does not confirm
  a dangerous operation, using a quiet `--apt-text` focus ring instead of the
  accent (see **quiet-ring-for-destructive-cancel**) so the ring never reads as an
  alarm color on the safe button. Hosts that focus a form field instead pass
  `focusOnMount={false}`. When the preferred button is disabled or absent at
  mount, focus falls to the other one instead of nowhere (see
  **focus-fallback-to-other-button**).
- The busy spinner is exposed to assistive tech via `role="status"` and
  `aria-label="Working…"`, announcing the in-progress state.
- Color is carried by `Button` variants (theme tokens), keeping contrast
  consistent with the platform's button treatment.
- Touch target: `Button` at `size="sm"` renders `h-7` (28px) by default, below
  the 44×44pt guideline; `DialogActions` does not set the shared
  `--adh-button-min-height`/`--adh-button-min-width` CSS variables itself, so the
  rendered target is whatever the host's surface provides (a surface can raise
  the floor by setting those variables once on itself — see `Button`). See
  **touch-target-size** in Compliance.

