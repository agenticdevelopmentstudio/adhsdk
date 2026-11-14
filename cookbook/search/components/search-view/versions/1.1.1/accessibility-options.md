
- **Reduce Motion**: The loading skeleton uses `animate-pulse` (a CSS animation). On `prefers-reduced-motion: reduce`, this animation SHOULD be removed or replaced with a static appearance. This is a style concern, not specific to SearchView's behavior, so it defers to the host's style implementation.
- **Increase Contrast**: All text colors (`text-apt-*`) and backgrounds inherit from the design system's apt-* tokens. The host's design system is responsible for providing high-contrast variants; SearchView does not handle this.
- **Differentiate Without Color**: Error state is communicated with a red background and text color, but color is not the only signal — the error message text itself and the `role="alert"` announcement both convey the error independent of color.

