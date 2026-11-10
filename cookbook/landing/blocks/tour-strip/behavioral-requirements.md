
- **render-eyebrow**: Component MUST render an eyebrow text containing the step number, total steps, and eyebrow label in the format `Step {step} of {total} · {eyebrow}`.
- **render-promise**: Component MUST render the promise content as a paragraph element.
- **render-as-tour-screen**: Component MUST render as a full-viewport `Screen` with id `tour` and class `lp-tour`.
- **render-pillars-when-provided**: When `pillars` array is provided and non-empty, component MUST render each pillar with title and body in a dedicated card element.
- **render-back-navigation**: When `back` step is provided, component MUST render a link containing the step label and optional note, with a left arrow indicator.
- **render-next-navigation**: When `next` step is provided, component MUST render a link containing the step label and optional note, with a right arrow indicator.
- **omit-navigation-when-absent**: Component MUST NOT render back navigation link when `back` prop is undefined; MUST NOT render next navigation link when `next` prop is undefined.
- **steps-container-always-renders**: Component MUST render the `lp-tour__steps` container element regardless of whether `back` or `next` is provided, even when both are absent.
- **hide-arrow-from-assistive-tech**: Component MUST mark arrow indicators as decorative with `aria-hidden="true"`.
- **accept-react-node-promise**: The `promise` prop MUST accept any valid React node, in practice limited to phrasing content since it renders inside a `<p>` wrapper (see Edge Cases).
- **accept-note-on-navigation-steps**: Both `back` and `next` step objects MUST accept an optional `note` property to display explanatory text below the step label.

