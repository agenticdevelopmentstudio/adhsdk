
- **Reduce Motion**: The chevron rotation transition (150ms) SHOULD respect `prefers-reduced-motion`. When this preference is active, the chevron SHOULD change angle instantly without transition.
- **Increase Contrast**: The component uses `var(--color-text-dim)` and `var(--color-text-secondary)` on hover. These CSS variables SHOULD be defined to meet WCAG AA contrast requirements (4.5:1 for text) even when Increase Contrast is active.
- **Differentiate Without Color**: The component does not rely on color alone to convey state; the chevron's rotation provides a visual indicator independent of color.

