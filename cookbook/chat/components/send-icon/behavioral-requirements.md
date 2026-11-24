
- **render-svg-arrow**: Component MUST render as an SVG element with a `<line>` and a `<polygon>` forming a paper-plane-outline send arrow pointing from lower-left to upper-right (see #appearance/geometry).
- **use-current-color**: Component MUST use `currentColor` for the stroke color, allowing the icon to inherit text color from its parent context.
- **maintain-aspect-ratio**: Component MUST render at a fixed 20×20 size, using a fixed 20×20 `width`/`height` that renders a `0 0 24 24` viewBox, keeping the arrow square and undistorted. The icon does not grow or shrink when its parent container is resized.
- **remain-static**: Component MUST NOT respond to user interaction, state changes, or dynamic updates; it is a static presentation with no event handlers.
- **decorative-hidden**: Component MUST set `aria-hidden="true"` and `focusable="false"` on the `<svg>` so assistive technology skips the purely decorative graphic.
