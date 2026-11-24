
- Built on Base UI `ToggleGroup` + `Toggle`, so items are real toggle buttons with
  correct pressed semantics and roving-focus keyboard support (arrow keys move focus
  between items; Enter/Space activates) out of the box.
- The pressed/selected item is conveyed to assistive technology via the Base UI toggle's pressed state. Sighted users get only the `data-[pressed]` gold fill, with no non-color cue (weight, border or icon); this is a known gap (see Accessibility Options and Compliance).
- Focus is shown with a visible `focus-visible` gold ring built from tokens.
- The group SHOULD carry an `aria-label` (or `aria-labelledby`) naming what is being
  chosen — the demo uses `aria-label="Alignment"` — since a bare group of buttons is
  ambiguous to AT.
- Disabled items are exposed as disabled and are not focusable/operable.

