
- **Reduce Motion**: The lightweight variant transitions `opacity`, `visibility` and `transform` over `--popover-duration` (0.12s); under `prefers-reduced-motion: reduce` its CSS sets `--popover-lift` to `0px`, so the slide is removed and only the opacity/visibility fade remains. The full-featured variant's wrapper classes define no transition of its own; any animation comes from Base UI and SHOULD be disabled or shortened to instant when the system setting is on.
- **Increase Contrast**: Border and background colors SHOULD adapt to provide WCAG AA contrast ratios (4.5:1 for text, 3:1 for non-text elements) when high-contrast mode is active.

