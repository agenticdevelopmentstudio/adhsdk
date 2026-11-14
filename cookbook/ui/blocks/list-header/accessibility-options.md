
- **Reduce Motion**: `ListHeader` adds no animation of its own. The only motion in
  the header is the unconditional `transition-colors` the shared `Input`
  ([adhsdk.ingredient.ui.components.inputs.input](cookbook:0f5b7167-b375-4f44-977b-566f720a453d))
  applies to its border/ring on focus; honoring `prefers-reduced-motion` is that
  ingredient's requirement, and `ListHeader` inherits whatever it does. The source does not
  yet gate it, which Compliance records as a failed `reduced-motion` check.
- **Increase Contrast**: The component uses `apt-text-muted` and `apt-text-default`
  tokens; if the active theme applies increased-contrast overrides to those tokens,
  the component inherits them automatically.
- **Differentiate Without Color**: See **state-without-color**.

