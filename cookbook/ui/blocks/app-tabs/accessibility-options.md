
Not implemented in source. The component does not respond to Increase Contrast or Differentiate Without Color — it relies on the `apt-*` design tokens for color regardless of contrast mode. The hover/active text-color change uses Tailwind's `transition-colors` utility with no `motion-reduce:` variant, so it has no explicit reduced-motion handling; the transition animates colour only, with no movement (see `reduced-motion` in Compliance).

