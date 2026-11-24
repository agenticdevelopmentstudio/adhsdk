
Not implemented in source. The component does not respond to Increase Contrast or Differentiate Without Color — it relies on the `apt-*` design tokens for color regardless of contrast mode. The hover/active text-color change uses Tailwind's `transition-colors` utility with no `motion-reduce:` variant, so it does not honor the OS reduced-motion preference either (see `reduced-motion` in Compliance).

