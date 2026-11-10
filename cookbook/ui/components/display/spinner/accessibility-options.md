
| Option | Behavior |
|--------|----------|
| Reduce Motion | The plain `animate-spin` Tailwind utility does NOT respect `prefers-reduced-motion` on its own — Tailwind only suppresses the animation when composed with a `motion-safe:`/`motion-reduce:` variant, which this component does not use. The spinner keeps animating even when the OS/browser motion-reduction setting is enabled; a caller who needs to honor that preference must override the animation via `className` (see Edge Cases). |
| Increase Contrast | Not directly implemented in component. Foreground and background contrast depends on the parent container's background and the `text-apt-text-muted` color token; teams using the component SHOULD ensure the muted text color meets WCAG AA 4.5:1 contrast ratio against the background. Custom `className` overrides (e.g., `text-black` or `text-white`) can be used to achieve higher contrast if needed. |
| Differentiate Without Color | Not applicable. The component conveys loading state via motion (spin animation) and the aria-label, not by color alone. |

