
Not applicable — `AlertModal` is a presentational component that inherits behavior from `Dialog`, which does not expose per-instance configuration for platform accessibility features such as Reduce Motion, Increase Contrast, or Differentiate Without Color. Implementations MUST rely on platform-level media query support (e.g., `prefers-reduced-motion`) and shared CSS utilities in the Button and Dialog recipes.

