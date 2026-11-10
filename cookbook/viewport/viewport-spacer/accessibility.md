
The root element is a plain `div` with no ARIA role, no accessible label, and no `tabindex` — see **assistive-tech-invisible** and **root-element**. It is not a landmark, a live region, or a focusable element, so screen readers and other assistive technology skip over it entirely, exactly as a purely structural spacer should. Accessibility semantics for real content come from ViewportSpacer's children and sibling components, not from ViewportSpacer itself.

