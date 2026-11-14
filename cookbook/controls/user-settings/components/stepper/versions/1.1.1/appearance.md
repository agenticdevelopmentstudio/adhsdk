
- **Corner radius**: 4px (control-specific border radius; varies by platform design system)
- **Padding**: Buttons and input inherit field padding from the `{{app_prefix}}` field styling (reference implementation: 8px vertical × 12px horizontal)
- **Font**: 14px regular weight for input value (reference implementation; scale with the app's type tokens)
- **Background**: Input background uses the theme's surface/background color token; button backgrounds inherit from `{{app_prefix}}` field styling
- **Foreground/Text**: Theme text color token (reference implementation: dark text on light backgrounds)
- **Border**: 1px solid, theme border color token; focus state applies the theme's focus outline
- **Shadow**: None (flat design)
- **Min/Max size**: Minimum width determined by button size and input width; no maximum enforced

