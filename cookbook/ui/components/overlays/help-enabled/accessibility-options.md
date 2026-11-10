
- **Reduce Motion**: The component does not disable or gate its opacity/background transitions when the system's Reduce Motion preference is on. Tailwind's `transition-*` utility classes do not automatically honor `prefers-reduced-motion` — that requires an explicit `motion-reduce:` variant, which this component does not apply. This is a known gap in the current implementation.
- **Increase Contrast**: Badge color at `opacity-70` may not meet WCAG AA contrast on all backgrounds. See Design Decisions: "Badge contrast not guaranteed".
- **Differentiate Without Color**: The badge is an icon shape (Info symbol), not solely color- or opacity-based, so its meaning does not depend on a user perceiving color or the opacity change.

