
- The trigger is a real `<button>` with `aria-label="Markdown quick reference"`,
  so the accessible name is stable even when the visible label changes.
- Open/closed state is conveyed via the Popover's `aria-expanded` /
  `aria-controls` wiring on the trigger (from the shared primitive).
- Escape closes the popover; focus is restored to the trigger (handled by the
  shared `Popover`).
- The reference content is a semantic `<dl>` (term/description pairs), so the
  label↔snippet relationship is exposed to assistive tech.
- Content is reference-only (no focusable controls), so there is no focus trap to
  manage beyond the primitive's defaults.

