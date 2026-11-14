
- **Reduce Motion**: The shared `Input` component applies an unconditional
  `transition-colors` CSS transition on its border/ring when focus changes.
  That transition MUST respect the `prefers-reduced-motion` media query
  (disabling or shortening it); the source does not yet gate it behind that
  query.
- **Increase Contrast**: The component uses `apt-text-muted` and `apt-text-default`
  tokens; if the active theme applies increased-contrast overrides to those tokens,
  the component inherits them automatically.
- **Differentiate Without Color**: The component MUST NOT rely solely on color to
  convey state. The focus ring (border or outline) and the filled vs. empty state
  of the input MUST be distinguishable without color.

