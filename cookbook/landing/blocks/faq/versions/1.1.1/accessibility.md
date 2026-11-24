
- **Semantic role**: The native `<details>` and `<summary>` elements carry their standard ARIA semantics. Screen readers announce the summary as a disclosure button with expanded/collapsed state.
- **Keyboard navigation**: Tab navigation moves focus between summaries. Enter and Space toggle the open state. Arrow keys are not required (disclosure is a button, not a tree widget).
- **Screen reader announcement**: Screen readers announce the summary text and whether the disclosure is expanded or collapsed. The answer content is announced when the disclosure is expanded.
- **Label requirement**: Each summary MUST contain meaningful text that describes the question or topic (the `question` prop). This label is read by screen readers and serves as the button label.
- **No custom ARIA required**: The `<details>` and `<summary>` elements provide `role=button` and `aria-expanded` semantics automatically; no custom ARIA markup is needed.
- **Focus visibility**: The browser provides a focus indicator on the summary when navigated via keyboard. CSS may customize this via standard focus-visible styling.
- **Minimum touch target**: Not specified in source. Per [WCAG 2.2 SC 2.5.8 (Target Size Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html), the summary click target SHOULD be at least 24×24 CSS pixels (Level AA baseline); [WCAG 2.5.5 (Target Size, Level AAA)](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html) recommends the stricter 44×44 CSS pixels. Meeting either is the responsibility of the consuming stylesheet.

