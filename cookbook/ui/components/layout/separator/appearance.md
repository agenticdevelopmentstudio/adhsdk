
- **Thickness**: A hairline — the thinnest visually distinct line the platform can render — expressed on web as a 1 CSS px line (`h-px` / `w-px`; on a high-DPI screen that spans more than one device pixel). Thickness is the height for horizontal orientation and the width for vertical orientation.
- **Full span**: 100% of available width (horizontal) or height (vertical); does not constrain the thickness axis (height when horizontal, width when vertical).
- **Background**: Uses the border/separator color token (web: `bg-apt-border` Tailwind utility, mapped to the design system's border token; map to the equivalent border/separator token on other platforms).
- **Border**: None
- **Corner radius**: None
- **Shadow**: None
- **Shrink behavior**: MUST NOT shrink below its hairline thickness inside a flex layout (web: Tailwind `shrink-0`, i.e. `flex-shrink: 0`); it likewise does not expand beyond that thickness.

