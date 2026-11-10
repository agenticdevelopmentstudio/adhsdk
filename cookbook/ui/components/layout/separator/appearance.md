
- **Thickness**: A hairline — the thinnest visually distinct line the platform can render — expressed as 1px on web (height for horizontal orientation; width for vertical orientation).
- **Full span**: 100% of available width (horizontal) or height (vertical); does not constrain the orthogonal dimension.
- **Background**: Uses the border/separator color token (web: `bg-apt-border` Tailwind utility, mapped to the design system's border token; map to the equivalent border/separator token on other platforms).
- **Border**: None
- **Corner radius**: None
- **Shadow**: None
- **Shrink behavior**: MUST NOT shrink below its hairline thickness inside a flex layout (web: Tailwind `shrink-0`, i.e. `flex-shrink: 0`); it likewise does not expand beyond that thickness.

