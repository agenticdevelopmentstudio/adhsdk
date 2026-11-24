
- **Reduce Motion**: The `transition-colors` class applies a brief color-only fade (no transform or motion), so it is treated as exempt from Reduce Motion policies; the component does not itself read `prefers-reduced-motion`. Consumers whose design system wants zero transition can override with `transition-none` in their stylesheet.
- **Increase Contrast**: The `apt-gold` and `apt-border` tokens are theme-specific; high-contrast themes should override token values to ensure sufficient contrast (WCAG AA non-text contrast, SC 1.4.11: 3:1 for UI components).
- **Differentiate Without Color**: Not applicable; the component uses both color (gold vs. border) and shape (dot appears/disappears) to indicate state, providing non-color differentiation.

