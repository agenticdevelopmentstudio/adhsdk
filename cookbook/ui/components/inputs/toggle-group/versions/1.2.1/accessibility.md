
- Built on Base UI `ToggleGroup` + `Toggle`, so items are real toggle buttons with
  correct pressed semantics and roving-focus keyboard support (arrow keys move focus
  between items; Enter/Space activates) out of the box.
- The pressed/selected item is conveyed via the Base UI toggle's pressed state, not
  color alone — the `data-[pressed]` gold fill is the visual layer on top of it.
- Focus is shown with a visible `focus-visible` gold ring built from tokens.
- The group SHOULD carry an `aria-label` (or `aria-labelledby`) naming what is being
  chosen — the demo uses `aria-label="Alignment"` — since a bare group of buttons is
  ambiguous to AT.
- Disabled items are exposed as disabled and are not focusable/operable.

