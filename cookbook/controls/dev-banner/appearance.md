
- **Container**: Non-interactive, block-level element with base class `awt-dev-banner`; the container does not intercept pointer/click events.
- **Background**: Dark, semi-transparent (near-black at roughly 40% opacity).
- **Border**: ~2pt solid, warm gold/tan, the same hue as the text.
- **Corner radius**: ~6pt.
- **Shadow/glow**: Soft two-layer gold-tinted glow around the container's edge.
- **Text**: Monospace family, ~0.85rem (relative to the root font size), medium weight, wide letter-spacing, uppercase transform, single line with no wrapping — long text overflows rather than wraps.
- **Foreground/Text color**: Warm gold/tan, matching the border.
- **Padding**: ~0.5rem vertical × 1rem horizontal.
- **Dynamic positioning class**: `awt-dev-banner--{position}` where `{position}` is either `'fixed'` or `'static'`.
  - **Fixed**: Anchored near the top of the viewport, horizontally centered, tilted -8° like a diagonal ribbon, stacked above most other content.
  - **Static**: Rendered inline in the document flow at its natural position, with the same -8° tilt, not anchored to the viewport.
- **Custom classes**: Applied via the `className` prop and appended to the class list.
- **Text content**: Renders the message string directly as a text node within the container.

