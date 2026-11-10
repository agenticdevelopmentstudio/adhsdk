
- **Layout**: Full viewport, wrapped in `Screen` and `Wrap` components for consistent site layout
- **Eyebrow**: Renders with class `lp-eyebrow`; inherits color and typography from eyebrow styling
- **Promise paragraph**: Renders with class `lp-tour__promise`; serves as primary visual hierarchy element
- **Pillar cards**: Each renders with class `lp-card` containing `<h3>` title and `<p>` body; organized in grid under class `lp-tour__pillars`
- **Navigation steps container**: Renders with class `lp-tour__steps`
- **Navigation links**: Each renders with class `lp-tour__step` plus direction modifier (`lp-tour__step--back` or `lp-tour__step--next`)
- **Arrow indicators**: Render with class `lp-tour__arrow` using Unicode arrows (← for back, → for next)
- **Typography in navigation**: Step label renders in `<b>` (bold); optional note renders in `<em>` (emphasis)

