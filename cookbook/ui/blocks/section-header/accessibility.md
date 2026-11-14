
- **Semantic heading**: Title is rendered as an `<h2>` to establish document outline hierarchy.
- **Help button label**: `aria-label="About this section"` describes the button purpose for screen readers.
- **Popover keyboard**: The help trigger is activated by click, Enter, or Space. Opening, closing (Escape or an outside interaction), and returning focus to the trigger are the underlying Popover component's behavior — see the **escape-closes** and **return-focus-on-close** requirements of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)).
- **Text content**: Eyebrow and title content are read as-is; no additional aria-labels required if text is meaningful.
- **title-contrast**: NEEDS REVIEW: Not implemented in source. The title uses the `apt-gold` token and the eyebrow `apt-text-dim` at 0.65rem; the source states no contrast ratio against the surface in any theme, so a per-theme measurement against 4.5:1 (WCAG 1.4.3) would settle it.
- **Hoisted heading**: When hoisted, the heading semantics come from the strip's title cell (`role="heading"`, `aria-level="2"`), not from an h2 in the pane.
- **Icon-only button**: Help button contains only an icon; `aria-label` is REQUIRED to provide accessible name.

