
- **Reduce Motion**: The hover/focus-visible text-color change uses Tailwind's `transition-colors` utility with no `motion-safe:`/`motion-reduce:` variant, so it does not automatically honor the OS reduced-motion preference — Tailwind's `transition-*` utilities apply unconditionally unless a `motion-*` variant is added. Consumers needing strict reduced-motion compliance should override with a `motion-reduce:transition-none` class.
- **Increase Contrast**: Component text and borders use CSS custom properties (`apt-text`, `apt-gold`, `apt-border`) which SHOULD be overridden in high-contrast themes. Not a component responsibility.
- **Differentiate Without Color**: Component uses both color (gold) and position (border underline) to indicate active state; active state is distinguishable without color alone.

