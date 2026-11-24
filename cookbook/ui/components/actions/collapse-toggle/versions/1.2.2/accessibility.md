
- **Role**: Button (semantic `<button>` element)
- **Label requirements**: The `aria-label` is always present and dynamically set based on state. The label MUST include the region name from the `label` prop so users understand what is being toggled.
- **State announcement**: The `aria-expanded` attribute indicates the expanded/collapsed state to assistive technologies.
- **Region association**: When `controls` is provided, `aria-controls` links the button to the region it controls, allowing assistive technology users to navigate directly to that region.
- **Keyboard navigation**: The button is keyboard-accessible via the standard HTML button element; keyboard focus is visible via the `focus-visible:ring` style.
- **minimum-tap-target**: NEEDS REVIEW: Not implemented in source. The source applies `px-1` (0.25rem horizontal padding) and no width, height, or minimum-size rule, so the hit area is exactly the inherited `font-mono` glyph box plus that padding — at a typical 14px rail font this lands well under the 44×44pt target the ingredient template names; measuring the rendered button at its two call sites (the TopicDetail rail and the theme-editor column list) against the 44×44pt floor, plus a decision on whether to pad the button itself or enlarge the surrounding row's hit area, would settle it.

